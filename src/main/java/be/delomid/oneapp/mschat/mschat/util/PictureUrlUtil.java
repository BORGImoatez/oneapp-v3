package be.delomid.oneapp.mschat.mschat.util;

public class PictureUrlUtil {

    public static String normalizePictureUrl(String pictureUrl) {
        if (pictureUrl == null) {
            return null;
        }

        if (pictureUrl.startsWith("/api/files/")) {
            return pictureUrl.replace("/api/files/", "/files/");
        }

        return pictureUrl;
    }
}
