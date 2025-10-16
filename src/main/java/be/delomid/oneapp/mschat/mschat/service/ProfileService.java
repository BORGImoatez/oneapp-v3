package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.ChangePasswordRequest;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.dto.UpdateProfileRequest;
import be.delomid.oneapp.mschat.mschat.model.Resident;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import be.delomid.oneapp.mschat.mschat.util.PictureUrlUtil;
import be.delomid.oneapp.mschat.mschat.util.SecurityContextUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProfileService {

    private final ResidentRepository residentRepository;
    private final PasswordEncoder passwordEncoder;
    private final String uploadDir = "uploads/profiles";

    @Transactional
    public ResidentDto updateProfile(UpdateProfileRequest request) {
        String userId = SecurityContextUtil.getCurrentUserId();
        log.debug("Updating profile for user: {}", userId);

        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));

        if (request.getEmail() != null && !request.getEmail().equals(resident.getEmail())) {
            residentRepository.findByEmail(request.getEmail()).ifPresent(existing -> {
                if (!existing.getIdUsers().equals(userId)) {
                    throw new IllegalArgumentException("Email already exists: " + request.getEmail());
                }
            });
            resident.setEmail(request.getEmail());
        }

        if (request.getFname() != null) {
            resident.setFname(request.getFname());
        }

        if (request.getLname() != null) {
            resident.setLname(request.getLname());
        }

        if (request.getPhoneNumber() != null) {
            resident.setPhoneNumber(request.getPhoneNumber());
        }

        resident = residentRepository.save(resident);
        log.debug("Profile updated successfully for user: {}", userId);

        return convertToDto(resident);
    }

    @Transactional
    public ResidentDto uploadProfilePicture(MultipartFile file) throws IOException {
        String userId = SecurityContextUtil.getCurrentUserId();
        log.debug("Uploading profile picture for user: {}", userId);

        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));

        if (file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("File must be an image");
        }

        Path uploadPath = Paths.get(uploadDir);
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        String originalFilename = file.getOriginalFilename();
        String extension = originalFilename != null && originalFilename.contains(".")
                ? originalFilename.substring(originalFilename.lastIndexOf("."))
                : ".jpg";
        String filename = userId + "_" + UUID.randomUUID() + extension;
        Path filePath = uploadPath.resolve(filename);

        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        String pictureUrl = "/files/profiles/" + filename;
        resident.setPicture(pictureUrl);
        resident = residentRepository.save(resident);

        log.debug("Profile picture uploaded successfully for user: {}", userId);

        return convertToDto(resident);
    }

    @Transactional
    public void deleteProfilePicture() {
        String userId = SecurityContextUtil.getCurrentUserId();
        log.debug("Deleting profile picture for user: {}", userId);

        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));

        if (resident.getPicture() != null) {
            String filename = resident.getPicture().substring(resident.getPicture().lastIndexOf("/") + 1);
            Path filePath = Paths.get(uploadDir).resolve(filename);
            try {
                Files.deleteIfExists(filePath);
            } catch (IOException e) {
                log.error("Failed to delete profile picture file: {}", filename, e);
            }
        }

        resident.setPicture(null);
        residentRepository.save(resident);

        log.debug("Profile picture deleted successfully for user: {}", userId);
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        String userId = SecurityContextUtil.getCurrentUserId();
        log.debug("Changing password for user: {}", userId);

        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));

        if (!passwordEncoder.matches(request.getCurrentPassword(), resident.getPassword())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }

        resident.setPassword(passwordEncoder.encode(request.getNewPassword()));
        residentRepository.save(resident);

        log.debug("Password changed successfully for user: {}", userId);
    }

    public ResidentDto getCurrentProfile() {
        String userId = SecurityContextUtil.getCurrentUserId();
        log.debug("Getting current profile for user: {}", userId);

        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));

        return convertToDto(resident);
    }

    private ResidentDto convertToDto(Resident resident) {
        String picture = PictureUrlUtil.normalizePictureUrl(resident.getPicture());
        if (picture != null && !picture.equals(resident.getPicture())) {
            resident.setPicture(picture);
            residentRepository.save(resident);
            log.debug("Fixed picture URL for user {}: {}", resident.getIdUsers(), picture);
        }

        return ResidentDto.builder()
                .idUsers(resident.getIdUsers())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .email(resident.getEmail())
                .phoneNumber(resident.getPhoneNumber())
                .picture(picture)
                .role(resident.getRole())
                .accountStatus(resident.getAccountStatus())
                .managedBuildingId(resident.getManagedBuildingId())
                .managedBuildingGroupId(resident.getManagedBuildingGroupId())
                .createdAt(resident.getCreatedAt())
                .updatedAt(resident.getUpdatedAt())
                .build();
    }
}
