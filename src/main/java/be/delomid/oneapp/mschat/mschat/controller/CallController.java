package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.CallDto;
import be.delomid.oneapp.mschat.mschat.service.CallService;
import be.delomid.oneapp.mschat.mschat.util.SecurityContextUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/calls")
public class CallController {

    @Autowired
    private CallService callService;

    @PostMapping("/initiate")
    public ResponseEntity<CallDto> initiateCall(@RequestBody Map<String, Object> request) {
        try {
            String callerId = SecurityContextUtil.getCurrentUserId();
            Long channelId = Long.parseLong(request.get("channelId").toString());
            String receiverId = request.get("receiverId").toString();

            CallDto call = callService.initiateCall(callerId, channelId, receiverId);
            return ResponseEntity.ok(call);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{callId}/answer")
    public ResponseEntity<CallDto> answerCall(@PathVariable Long callId) {
        try {
            String userId = SecurityContextUtil.getCurrentUserId();
            CallDto call = callService.answerCall(callId, userId);
            return ResponseEntity.ok(call);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{callId}/end")
    public ResponseEntity<CallDto> endCall(@PathVariable Long callId) {
        try {
            String userId = SecurityContextUtil.getCurrentUserId();
            CallDto call = callService.endCall(callId, userId);
            return ResponseEntity.ok(call);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{callId}/reject")
    public ResponseEntity<CallDto> rejectCall(@PathVariable Long callId) {
        try {
            String userId = SecurityContextUtil.getCurrentUserId();
            CallDto call = callService.rejectCall(callId, userId);
            return ResponseEntity.ok(call);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/channel/{channelId}")
    public ResponseEntity<List<CallDto>> getCallHistory(@PathVariable Long channelId) {
        try {
            String userId = SecurityContextUtil.getCurrentUserId();
            List<CallDto> calls = callService.getCallHistory(channelId, userId);
            return ResponseEntity.ok(calls);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
