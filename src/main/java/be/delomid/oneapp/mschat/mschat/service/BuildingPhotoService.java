package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.BuildingPhotoDto;
import be.delomid.oneapp.mschat.mschat.model.Building;
import be.delomid.oneapp.mschat.mschat.model.BuildingPhoto;
import be.delomid.oneapp.mschat.mschat.repository.BuildingPhotoRepository;
import be.delomid.oneapp.mschat.mschat.repository.BuildingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BuildingPhotoService {

    private final BuildingPhotoRepository buildingPhotoRepository;
    private final BuildingRepository buildingRepository;

    @Transactional
    public BuildingPhotoDto addPhoto(String buildingId, String photoUrl, String description, Integer order) {
        log.debug("Adding photo to building: {}", buildingId);

        Building building = buildingRepository.findById(buildingId)
                .orElseThrow(() -> new IllegalArgumentException("Building not found: " + buildingId));

        BuildingPhoto photo = BuildingPhoto.builder()
                .building(building)
                .photoUrl(photoUrl)
                .description(description)
                .photoOrder(order != null ? order : 0)
                .build();

        photo = buildingPhotoRepository.save(photo);
        log.debug("Photo added successfully: {}", photo.getId());

        return convertToDto(photo);
    }

    public List<BuildingPhotoDto> getPhotosByBuildingId(String buildingId) {
        log.debug("Getting photos for building: {}", buildingId);
        List<BuildingPhoto> photos = buildingPhotoRepository.findByBuildingBuildingIdOrderByPhotoOrderAsc(buildingId);
        return photos.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deletePhoto(Long photoId) {
        log.debug("Deleting photo: {}", photoId);
        if (!buildingPhotoRepository.existsById(photoId)) {
            throw new IllegalArgumentException("Photo not found: " + photoId);
        }
        buildingPhotoRepository.deleteById(photoId);
    }

    @Transactional
    public BuildingPhotoDto updatePhotoOrder(Long photoId, Integer newOrder) {
        log.debug("Updating photo order: {}, new order: {}", photoId, newOrder);

        BuildingPhoto photo = buildingPhotoRepository.findById(photoId)
                .orElseThrow(() -> new IllegalArgumentException("Photo not found: " + photoId));

        photo.setPhotoOrder(newOrder);
        photo = buildingPhotoRepository.save(photo);

        return convertToDto(photo);
    }

    private BuildingPhotoDto convertToDto(BuildingPhoto photo) {
        return BuildingPhotoDto.builder()
                .id(photo.getId())
                .buildingId(photo.getBuilding().getBuildingId())
                .photoUrl(photo.getPhotoUrl())
                .photoOrder(photo.getPhotoOrder())
                .description(photo.getDescription())
                .createdAt(photo.getCreatedAt())
                .updatedAt(photo.getUpdatedAt())
                .build();
    }
}
