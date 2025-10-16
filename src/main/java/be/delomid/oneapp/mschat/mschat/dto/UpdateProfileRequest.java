package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Data;

@Data
public class UpdateProfileRequest {
    private String fname;
    private String lname;
    private String email;
    private String phoneNumber;
}
