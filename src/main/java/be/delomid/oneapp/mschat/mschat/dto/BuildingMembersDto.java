package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BuildingMembersDto {
    private List<ResidentSummaryDto> residents;
    private List<ApartmentSummaryDto> apartments;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ResidentSummaryDto {
        private String id;
        private String email;
        private String firstName;
        private String lastName;
        private String apartmentId;
        private String apartmentNumber;
        private String floor;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ApartmentSummaryDto {
        private String id;
        private String apartmentNumber;
        private String floor;
    }
}
