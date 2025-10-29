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
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CallService {

    private final CallRepository callRepository;
    private final ChannelRepository channelRepository;
    private final ResidentRepository residentRepository;
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
