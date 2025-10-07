package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.AccountStatus;
import be.delomid.oneapp.mschat.mschat.model.UserRole;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ResidentDto {
    private String idUsers;
    private String fname;
    private String lname;
    private String email;
    private String phoneNumber;
    private String picture;
    private String apartmentId;
    private String buildingId;
    private UserRole role;
    private AccountStatus accountStatus;
    private String managedBuildingId;
    private String managedBuildingGroupId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}