package be.delomid.oneapp.mschat.mschat.controller;


import be.delomid.oneapp.mschat.mschat.dto.MessageDto;
import be.delomid.oneapp.mschat.mschat.dto.SendMessageRequest;
import be.delomid.oneapp.mschat.mschat.dto.SharedMediaDto;
import be.delomid.oneapp.mschat.mschat.model.MessageType;
import be.delomid.oneapp.mschat.mschat.service.MessageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/messages")
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    @PostMapping
    public ResponseEntity<MessageDto> sendMessage(
            @Valid @RequestBody SendMessageRequest request,
            Authentication authentication) {
        
        String userId = getUserId(authentication);
        MessageDto message = messageService.sendMessage(request, userId);
        return ResponseEntity.ok(message);
    }

    @GetMapping("/channel/{channelId}")
    public ResponseEntity<Page<MessageDto>> getChannelMessages(
            @PathVariable Long channelId,
            Authentication authentication,
            Pageable pageable) {
        
        String userId = getUserId(authentication);
        Page<MessageDto> messages = messageService.getChannelMessages(channelId, userId, pageable);
        return ResponseEntity.ok(messages);
    }

    @PutMapping("/{messageId}")
    public ResponseEntity<MessageDto> editMessage(
            @PathVariable Long messageId,
            @RequestParam String content,
            Authentication authentication) {
        
        String userId = getUserId(authentication);
        MessageDto message = messageService.editMessage(messageId, content, userId);
        return ResponseEntity.ok(message);
    }

    @DeleteMapping("/{messageId}")
    public ResponseEntity<Void> deleteMessage(
            @PathVariable Long messageId,
            Authentication authentication) {
        
        String userId = getUserId(authentication);
        messageService.deleteMessage(messageId, userId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/channel/{channelId}/media")
    public ResponseEntity<Page<SharedMediaDto>> getSharedMedia(
            @PathVariable Long channelId,
            @RequestParam(required = false) String type,
            Authentication authentication,
            Pageable pageable) {

        String userId = getUserId(authentication);
        Page<SharedMediaDto> media;

        if (type != null && !type.isEmpty()) {
            try {
                MessageType messageType = MessageType.valueOf(type.toUpperCase());
                media = messageService.getSharedMediaByType(channelId, messageType, userId, pageable);
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().build();
            }
        } else {
            media = messageService.getSharedMedia(channelId, userId, pageable);
        }

        return ResponseEntity.ok(media);
    }

    @GetMapping("/channel/{channelId}/media/images")
    public ResponseEntity<Page<SharedMediaDto>> getSharedImages(
            @PathVariable Long channelId,
            Authentication authentication,
            Pageable pageable) {

        String userId = getUserId(authentication);
        Page<SharedMediaDto> media = messageService.getSharedMediaByType(channelId, MessageType.IMAGE, userId, pageable);
        return ResponseEntity.ok(media);
    }

    @GetMapping("/channel/{channelId}/media/videos")
    public ResponseEntity<Page<SharedMediaDto>> getSharedVideos(
            @PathVariable Long channelId,
            Authentication authentication,
            Pageable pageable) {

        String userId = getUserId(authentication);
        Page<SharedMediaDto> media = messageService.getSharedMediaByType(channelId, MessageType.VIDEO, userId, pageable);
        return ResponseEntity.ok(media);
    }

    @GetMapping("/channel/{channelId}/media/documents")
    public ResponseEntity<Page<SharedMediaDto>> getSharedDocuments(
            @PathVariable Long channelId,
            Authentication authentication,
            Pageable pageable) {

        String userId = getUserId(authentication);
        Page<SharedMediaDto> media = messageService.getSharedMediaByType(channelId, MessageType.FILE, userId, pageable);
        return ResponseEntity.ok(media);
    }

    private String getUserId(Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        return userDetails.getUsername();
    }
}