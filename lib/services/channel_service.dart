@@ .. @@
   public Optional<ChannelDto> getOrCreateOneToOneChannel(String userId1, String userId2) {
         Optional<Channel> existingChannel = channelRepository.findOneToOneChannel(userId1, userId2);

         if (existingChannel.isPresent()) {
-            return Optional.of(convertToDto(existingChannel.get()));
+            return Optional.of(convertToDto(existingChannel.get(), userId1));
         }

-        // Créer un nouveau canal one-to-one
+        // Récupérer les informations des deux utilisateurs pour créer le nom
        return convertToDto(channel, null);
    }
    
    private ChannelDto convertToDto(Channel channel, String currentUserId) {
+        Resident user1 = residentRepository.findById(userId1)
        
        String displayName = channel.getName();
        
        // Pour les canaux ONE_TO_ONE, afficher le nom de l'autre utilisateur
        if (channel.getType() == ChannelType.ONE_TO_ONE && currentUserId != null) {
            List<ChannelMember> members = channelMemberRepository.findActiveByChannelId(channel.getId());
            for (ChannelMember member : members) {
                if (!member.getUserId().equals(currentUserId)) {
                    Optional<Resident> otherUser = residentRepository.findById(member.getUserId());
                    if (otherUser.isPresent()) {
                        displayName = otherUser.get().getFname() + " " + otherUser.get().getLname();
                        break;
                    }
                }
            }
        }
+                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId1));
+        Resident user2 = residentRepository.findById(userId2)
+                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId2));
                .name(displayName)
+        // Créer un nouveau canal one-to-one avec le nom de l'autre utilisateur
         CreateChannelRequest request = new CreateChannelRequest();
-        request.setName("Direct Message");
+        request.setName(user2.getFname() + " " + user2.getLname());
         request.setType(ChannelType.ONE_TO_ONE);
         request.setIsPrivate(true);
         request.setMemberIds(List.of(userId2));

-        return Optional.of(createChannel(request, userId1));
+        ChannelDto channel = createChannel(request, userId1);
+        return Optional.of(channel);
     }