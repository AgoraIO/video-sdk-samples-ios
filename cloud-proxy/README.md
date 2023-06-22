# Connect through restricted networks with Cloud Proxy

You use Agora Cloud Proxy to ensure reliable connectivity for your users when they connect from an environment with a restricted network.

## Understand the tech of Cloud Proxy

To accommodate your end users’ firewall settings and business needs, Cloud Proxy offers the following operating modes:

### Automatic

The default setting. In the Automatic mode of Cloud Proxy, Video SDK first attempts a direct connection to Agora SD-RTN™; if the attempt fails, Video SDK automatically falls back and sends media securely on TLS 443. This is best practice when you are not sure if your end users are behind a firewall. Sending media over TLS 443 may not have as high quality UDP. However, a connection on TLS 443 works through most firewalls.

### Force UDP

In the Force UDP mode of Cloud Proxy, Video SDK securely sends media over UDP only. Your end users’ firewall must be configured to trust a list of allowed IP address. This is best practice when your end users are behind a firewall and require media with the highest possible quality. This mode does not support pushing streams to the CDN or relaying streams across channels.

### Force TCP

In the Force TCP mode of Cloud Proxy, Video SDK securely sends media over TLS 443 only. This is best practice when your end users are behind a firewall and the firewall’s security policies only allow media to flow through TLS 443. In some cases the firewall might trust any traffic over TLS 443. However, in many cases the firewall is configured to trust only a specific range of IP addresses sending traffic over TLS 443. In this case, your end user’s firewall must be configured to trust a list of allowed IP address. Media quality might be impacted if network conditions degrade.

## Topics

### Enabling Cloud Proxy

Once choosing a proxy type, you need to call `agoraEngine.setCloudProxy` with your chosen proxy type, as shown in [CloudProxyManager](CloudProxyView.swift#L18). .

## Full Documentation

[Agora's full token authentication guide](https://docs.agora.io/en/interactive-live-streaming/develop/cloud-proxy?platform=ios)

