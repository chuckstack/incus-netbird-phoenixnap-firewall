# variables
INCUS_NETWORK=incusbr-iso
INCUS_PROFILE=isolated
INCUS_ACL=public-only

# delete artifacts
incus profile delete $INCUS_PROFILE
incus network delete $INCUS_NETWORK
incus network acl delete $INCUS_ACL

