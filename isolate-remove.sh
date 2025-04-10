
# NOTE: delete all instances using the below profile before continuing

# variables
INCUS_NETWORK=incusbr-iso-aa
INCUS_PROFILE=isolated-aa
INCUS_ACL=public-only

# delete artifacts
incus profile delete $INCUS_PROFILE
incus network delete $INCUS_NETWORK
incus network acl delete $INCUS_ACL
