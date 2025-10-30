package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.CallDto;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import be.delomid.oneapp.mschat.mschat.util.PictureUrlUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CallService {

    private final CallRepository callRepository;
    private final ChannelRepository channelRepository;
    private final ResidentRepository residentRepository;
    private final MessageRepository messageRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Transactional
    public CallDto initiateCall(String callerId, Long channelId, String receiverId) {
        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new RuntimeException("Channel not found"));

        Resident caller = residentRepository.findById(callerId)
                .orElseThrow(() -> new RuntimeException("Caller not found"));

        Resident receiver = residentRepository.findById(receiverId)
                .orElseThrow(() -> new RuntimeException("Receiver not found"));

        Call call = new Call();
        call.setChannel(channel);
        call.setCaller(caller);
        call.setReceiver(receiver);
        call.setStatus(CallStatus.INITIATED);
        call = callRepository.save(call);

        CallDto callDto = convertToDto(call);

        messagingTemplate.convertAndSendToUser(
                receiverId,
                "/queue/call",
                callDto
        );

        return callDto;
    }

    @Transactional
    public CallDto answerCall(Long callId, String userId) {
        Call call = callRepository.findById(callId)
                .orElseThrow(() -> new RuntimeException("Call not found"));

        if (!call.getReceiver().getIdUsers().equals(userId)) {
            throw new RuntimeException("Unauthorized to answer this call");
        }

        call.setStatus(CallStatus.ANSWERED);
        call.setStartedAt(LocalDateTime.now());
        call = callRepository.save(call);

        CallDto callDto = convertToDto(call);

        messagingTemplate.convertAndSendToUser(
                call.getCaller().getIdUsers(),
                "/queue/call",
                callDto
        );

        return callDto;
    }

    @Transactional
    public CallDto endCall(Long callId, String userId) {
        Call call = callRepository.findById(callId)
                .orElseThrow(() -> new RuntimeException("Call not found"));

        if (!call.getCaller().getIdUsers().equals(userId) &&
                !call.getReceiver().getIdUsers().equals(userId)) {
            throw new RuntimeException("Unauthorized to end this call");
        }

        call.setStatus(CallStatus.ENDED);
        call.setEndedAt(LocalDateTime.now());

        if (call.getStartedAt() != null) {
            Duration duration = Duration.between(call.getStartedAt(), call.getEndedAt());
            call.setDurationSeconds((int) duration.getSeconds());
        } else {
            // Si l'appel n'a jamais été répondu, c'est un appel manqué
            call.setStatus(CallStatus.MISSED);
            createCallMessage(call);
        }

        call = callRepository.save(call);

        CallDto callDto = convertToDto(call);

        String otherUserId = call.getCaller().getIdUsers().equals(userId)
                ? call.getReceiver().getIdUsers()
                : call.getCaller().getIdUsers();

        messagingTemplate.convertAndSendToUser(
                otherUserId,
                "/queue/call",
                callDto
        );

        return callDto;
    }

    @Transactional
    public CallDto rejectCall(Long callId, String userId) {
        Call call = callRepository.findById(callId)
                .orElseThrow(() -> new RuntimeException("Call not found"));

        if (!call.getReceiver().getIdUsers().equals(userId)) {
            throw new RuntimeException("Unauthorized to reject this call");
        }

        call.setStatus(CallStatus.REJECTED);
        call = callRepository.save(call);

        // Créer un message d'appel manqué dans le canal
        createCallMessage(call);

        CallDto callDto = convertToDto(call);

        messagingTemplate.convertAndSendToUser(
                call.getCaller().getIdUsers(),
                "/queue/call",
                callDto
        );

        return callDto;
    }

    public List<CallDto> getCallHistory(Long channelId, String userId) {
        List<Call> calls = callRepository.findCallsByChannelAndUser(channelId, userId);
        return calls.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    private void createCallMessage(Call call) {
        try {
            Message message = Message.builder()
                    .channel(call.getChannel())
                    .senderId(call.getCaller().getIdUsers())
                    .content("Appel " + (call.getStatus() == CallStatus.MISSED ? "manqué" : "refusé"))
                    .type(MessageType.CALL)
                    .callId(call.getId())
                    .isEdited(false)
                    .isDeleted(false)
                    .build();

            messageRepository.save(message);

            // Envoyer le message via WebSocket
            be.delomid.oneapp.mschat.mschat.dto.MessageDto messageDto = be.delomid.oneapp.mschat.mschat.dto.MessageDto.builder()
                    .id(message.getId())
                    .channelId(message.getChannel().getId())
                    .senderId(message.getSenderId())
                    .senderFname(call.getCaller().getFname())
                    .senderLname(call.getCaller().getLname())
                    .senderPicture(PictureUrlUtil.normalizePictureUrl(call.getCaller().getPicture()))
                    .content(message.getContent())
                    .type(message.getType())
                    .callData(buildCallData(call))
                    .isEdited(message.getIsEdited())
                    .isDeleted(message.getIsDeleted())
                    .createdAt(message.getCreatedAt())
                    .build();

            messagingTemplate.convertAndSend("/topic/channel/" + call.getChannel().getId(), messageDto);
        } catch (Exception e) {
            // Log l'erreur mais ne pas faire échouer l'appel
            System.err.println("Error creating call message: " + e.getMessage());
        }
    }

    private Map<String, Object> buildCallData(Call call) {
        Map<String, Object> callData = new HashMap<>();
        callData.put("callId", call.getId());
        callData.put("status", call.getStatus().name());
        callData.put("callerId", call.getCaller().getIdUsers());
        callData.put("callerName", call.getCaller().getFname() + " " + call.getCaller().getLname());
        callData.put("receiverId", call.getReceiver().getIdUsers());
        callData.put("receiverName", call.getReceiver().getFname() + " " + call.getReceiver().getLname());
        callData.put("durationSeconds", call.getDurationSeconds());
        callData.put("createdAt", call.getCreatedAt());
        return callData;
    }

    private CallDto convertToDto(Call call) {
        CallDto dto = new CallDto();
        dto.setId(call.getId());
        dto.setChannelId(call.getChannel().getId());
        dto.setCallerId(call.getCaller().getIdUsers());
        dto.setCallerName(call.getCaller().getFname() + " " + call.getCaller().getLname());
        dto.setCallerAvatar(PictureUrlUtil.normalizePictureUrl(call.getCaller().getPicture()));
        dto.setReceiverId(call.getReceiver().getIdUsers());
        dto.setReceiverName(call.getReceiver().getFname() + " " + call.getReceiver().getLname());
        dto.setReceiverAvatar(PictureUrlUtil.normalizePictureUrl(call.getReceiver().getPicture()));
        dto.setStartedAt(call.getStartedAt());
        dto.setEndedAt(call.getEndedAt());
        dto.setDurationSeconds(call.getDurationSeconds());
        dto.setStatus(call.getStatus().name());
        dto.setCreatedAt(call.getCreatedAt());
        return dto;
    }
}
