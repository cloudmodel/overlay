CloudModel Overlay
==================

Install layman

    emerge layman

Add the repository URL in `/etc/layman/layman.cfg`

    https://raw.github.com/cloudmodel/overlay/master/repositories.xml

Synchronize the repositories and add the overlay

    layman -S
    layman -a cloudmodel

Add `/var/lib/layman/cloudmodel` to the `PORTDIR_OVERLAY` variable in `/etc/make.conf`
