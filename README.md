# The Stone Cross Foundation

This is a collection of infrastructure files that power https://hrest.org.

To whoever it may concern: Feel free to extend this README with the necessary
notes, details, manifests, and specifications. Both our production and test
infra is still very much a work-in-progress, and it will only but grow together
with our website as it will encounter scale.

I suggest we preach ideas-first approach.

Whenever an idea comes up, it should be documented quickly so whoever might add
their input could do so as quickly as possible. This is especially important
for a volunteer cooperative that we are— it's always important to remember that
we don't have a dedicated DevOps team on payroll and by nature of it, there
absolutelyw will be chaos, and certain goals will take time to crystalise.

Better embrace this— and have these ideas outlined in whatever state and form.

## Overview

The current high-level view of everything is as follows:

- Cloudflare [WAF][26] and [Railgun][6].
- [AWS EC2][12] and the dedicated [Hetzner][1] servers.
- [Consul][14] will take care of discovery.
- [Nomad][15] is a capable scheduler.
- [Vault][16] keeps passwords, keys, certs, etc.— encrypted at rest.
- [Postgres][17] with various extensions and [pgpool][18].
- [Redis][5].
- [Synapse][27] is a E2EE chat server with [OIDC][29] support.
- [MapTiler][19] is a self-hosted tiling server.

>Note: The API back-end we have engineered can act as an [OpenID Connect][28]
provider, this is a means of authentication for our chat service that is a
secure E2EE Matrix homeserver implementation, it also a means for the third
parties to rely on us for authentication of applicants and volunteers. They
want to do that in order to have extra anti-fraud and request deduplication
capability.

Let's first take a look at [Consul Reference Architecture][20] which should be
a good starting point for all clusters based on Consul, and our case shouldn't
be too different. (However, if this ever turns out not to be the case, it must
be pointed out as soon as possible!) There's also a caveat that we're probably
not going to run five, but three nodes.

![Five nodes within distributed between three availability zones][21]

I mean, as long as these are not [Spot][22] instances, in that case we would
probably have to keep more just to stay safe. There might as well be quite a
benefit in doing so as "More nodes" usually means "More power" and provided
we're able to make a use of it, this should be good for us. However, if we
choose to do this we probably won't be able to apply for [Savings Plan][23]
because it doesn't cover Spot.

Consul's [Connect][24] provides full service discovery and mTLS service mesh.

What does it mean? Well, for starters it probably means that we wouldn't need
to maintain a VPN to keep our services connected, in my view this should
somewhat simplify the hybrid cluster setup that we're trying to achieve but
what do I know? I know nothing. At any rate, mTLS is good enough of a deal all
things considered. AFAIK people these days no longer go around spreading
unencrypted HTTP traffic like herpes.

Okay, now let's imagine, for a moment, that we have our network, we have our
discovery and whatnot, our nodes are well-connected, and our services can talk
to each other consistently. How do we get them on? Enter [Nomad][15]. From what
I hear, people have had somewhat mixed experiences with it, but so they have
with Kubernetes. I'm not too keen on gossip, and for this project would like to
make decisions based on simplicity and fact. Judging by what I've read on this
subject, Nomad seems like a decent enough scheduler, and [HCL][25] is a decent
enough configuration language, which would definitely seem like an improvement
had you put it up against the pages upon pages of YAML manifests commonly found
in Kubernetes of all things.

Now, the big question is whether if we can make it work for us.

I myself see no reason why it wouldn't, but this is no way to make an argument.
Instead, let's consider our requirements for once. In a very broad sense, we're
looking to schedule two kinds of workloads: the bandwidth-heavy user-facing API
things and the pesky QA/CI/CD things— all kinds of test and stage environments,
observability and business intelligence software. In other words, the services
we would want to spin whenever we need them, have them readily available, and
guarantee that they couldn't impact our production deployments all of a sudden.
The very reason we decided to push through the _hybrid_ approach was to avoid
serving traffic off AWS, and thus avoid paying the bandwidth bill. For this to
work, we want to keep our databases, the cache, and everything— as close as
possible to the traffic nodes, the primary disadvantage of this approach being
that everything kind of clumps together to form a monolith monstrosity.

Let's hope that Nomad can give us the necessary balance, because if it can't we
would have to resort back to square zero— K8s, and no engineering success story
would be lying here to be found. Not that I have anything against K8s, but this
shouldn't be too hard, right? To be clear, by _this_, I mean our data-driven
charity project. I truly believe that we can make our platform work like none
other, and perhaps as well as none other.

In my experience most of the benefits associated with K8s come from it being
managed for you, and much of it doesn't translate terribly well onto a hybrid
environment (and that's exactly what we're dealing with here.) I mean, we
probably could get away with managed K8s and Spot instances sporadically being
provisioned in AWS, but then again, the database can't be set up this way,
neither can the control plane really (these are three or more servers you're
going to keep for orchestrating purposes)— the cost of running this in AWS, or
anywhere else for that matter does skyrocket real quick, without even starting
to consider bandwidth; if the cloud VM pricing wouldn't kill us, the bandwidth
absolutely will.

Hence it was decided to run a pair of dedicated boxes in [Hetzner][1], where we
could provision our primary workload: the streaming-replicated [TimescaleDB][2]
with [PostGIS][3] and [PostgresML][4] on top of it, [Redis][5], and our backend
monolith-like API service written in Go. Now, at the end of the day, all this
circus must go to town— and for that purpose we enjoy [Cloudflare Railgun][6]—
a very particular piece of software, which functions as the ultimate solution
to bandwidth optimisation, caching, and whatnot. That is, if you can afford a
Cloudflare Business subscription; and due to courtesy of [Project Galileo][7]
indeed we can. This means that we can set up a load balancer however we want,
in fact it's very possible that we wouldn't need to, as the general load
balancer is likely to be redundant in our case. In fact, we could as well rely
on Cloudflare's [Load Balancer][8] directly, and make it spread the incoming
traffic over two or more of our Hetzner boxes. And these two can be setup as to
only accept Railgun requests from the Cloudflare subnets.

Thus we can expose our nice HA infrastructure nice and clean without seemingly
having to expose it at all.

In the worker plane, we will put a hardware firewall in place to only allow for
Cloudflare subnets and our AWS control plane subnet in order to leave the door
open for orchestration and the services within AWS perimiter. This means that
we can leverage Vault's [Auto Unseal][9] capability using [KMS][10] and rely on
[S3][11] for object storage if we don't want to maintain the object store of
our own, and we probably don't. Also, in order to keep the utilisation of these
control plane VMs high, we can put some of our mission-critical services there.
For the time being, we have the government-provided [ID][13] and bank acquiring
done within the API monolith, but there's room for improvement there: both may
become independent services sometime along the way. In this view, none of them
would ever come under load, of course as long as our Hetzner big-boys are able
to consistently respond to pressure. At any rate, we're not looking at Google
scale or anything; in fact, we would never exceed something like 10krpm. Also:
Please remember all of it is Railgun-bound!

I suggest we should seek simplicity if anything.

[1]:  https://www.hetzner.com/dedicated-rootserver
[2]:  https://www.timescale.com/
[3]:  https://postgis.net/
[4]:  https://postgresml.org/
[5]:  https://redis.com/
[6]:  https://www.cloudflare.com/en-gb/website-optimization/railgun/
[7]:  https://www.cloudflare.com/galileo/
[8]:  https://www.cloudflare.com/load-balancing/
[9]:  https://learn.hashicorp.com/collections/vault/auto-unseal
[10]: https://aws.amazon.com/kms/
[11]: https://aws.amazon.com/s3/
[12]: https://aws.amazon.com/ec2/
[13]: https://id.gov.ua/
[14]: https://www.consul.io/
[15]: https://www.nomadproject.io/
[16]: https://www.vaultproject.io/
[17]: https://www.postgresql.org/
[18]: https://pgpool.net/mediawiki/index.php/Main_Page
[19]: https://www.maptiler.com/server/
[20]: https://learn.hashicorp.com/tutorials/consul/reference-architecture
[21]: https://mktg-content-api-hashicorp.vercel.app/api/assets?product=tutorials&version=main&asset=public%2Fimg%2Fconsul%2Freference-architecture%2Fconsul-singleDC-5node-reference-architecture.png
[22]: https://aws.amazon.com/ec2/spot/
[23]: https://aws.amazon.com/savingsplans/
[24]: https://www.consul.io/docs/connect/connect-internals
[25]: https://github.com/hashicorp/hcl
[26]: https://www.cloudflare.com/waf
[27]: https://github.com/matrix-org/synapse
[28]: https://openid.net/connect/
[29]: https://matrix-org.github.io/synapse/latest/openid.html
