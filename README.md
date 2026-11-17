# Cloudsmith Technical Challenge

## Overview

This project demonstrates centralized artifact management and software supply chain security using Cloudsmith, GitHub Actions, and Policy as Code.

The implementation includes:
- Upstream proxying and caching for PyPI and Docker Hub.
- A GitHub Actions workflow consuming artifacts through Cloudsmith.
- A three-day package cooldown policy.
- Rego-based vulnerability detection and automatic quarantine.

## 1. Upstream Configuration

**Cloudsmith repository:** `aidanoc15/test`

Configured two upstream sources, both using **Cache and Proxy**:

| Upstream | Test artifact |
|---|---|
| PyPI | `numpy==2.2.6` |
| Docker Hub | `python:3.12-slim` |

Cache and Proxy were selected for our upstream sources to allow Cloudsmith to serve as a centralized repository for all public dependencies your developers may want to use. By ensuring everything passes through Cloudsmith we gain visibility into how and what dependencies are being consumed. This further allows us to establish a single point for enacting security policies around those dependencies. 

**Evidence:** [Upstream configuration](evidence/docker and pypu upstreams.png) · [Cached packages](evidence/cached packages.png)

## 2. GitHub Actions Workflow

The workflow authenticates to Cloudsmith, pulls a Python Docker image through the Docker registry, and runs a Python application that installs NumPy from the Cloudsmith PyPI index. This is all done using credentials stored as GitHub Actions Secrets. 

This establishes that that container images AND application dependencies can both be managed and retrieved through Cloudsmith, filling in gaps on both sides CI and CD side of things. It also shows the ease of implementation into workflow most DevSecOps teams are already going to be familiar with. 

**Result:** Successful execution, confirming that the container image and Python dependency were consumed through Cloudsmith.

**Evidence:** [Successful GitHub Actions run](evidence/succesful%20github%20actions%20run.png)

## 3. Cooldown Policy

Configured a **three-day cooldown period** for newly published Python and Docker package versions.

The policy hides versions that have not reached the minimum age threshold, reducing exposure to newly introduced and potentially unknown vulnerabilities and threats.

**Validation:**
- `boto3==1.44.4` — unavailable through Cloudsmith.
- `boto3==1.43.123` — downloaded successfully.

The three day cooldown period selected makes sense as a boilerplate policy to implement, however it does come with tradeoffs. While we do wish to maintain that developers can't download newly released versions that may contain unknown zero-days, there are instances where we are going to want developers to download new versions as soon as possible. One obvious example would be when new legitimate updates patching critical security flaws are released. In a real production environment I would suggest having some kind of process built out to handle these exceptions. 

**Evidence:** [Policy configuration](evidence/cooldown%20policy.png) · [Terminal test](evidence/cooldown%20policy%20terminal.png)

## 4. Rego Vulnerability Quarantine

Created a custom Rego policy named **High-risk vulnerabilities** that automatically quarantines packages with reported vulnerabilities meeting the following conditions:

- CVSS score ≥ 7.0.
- A fix is available.

**Validation:** Tested against `requests==2.19.1`.

Cloudsmith identified matching vulnerabilities, recorded the custom policy decision, and placed the package in quarantine. A subsequent pip download returned **HTTP 403 Forbidden**.

The decision logic for this policy is relatively standard but Cloudsmith does have the ability to get more granular and build out various different exceptions based on other vulnerability properties that are available. This is especially useful for organizations that want to tailor their risk tolerance. 

**Evidence:** [Rego policy](evidence/vulnerability%20quarantine%20policy.png) · [Decision log](evidence/vulnerability%20policy%20decision%20log.png) · [Quarantined package](evidence/screenshot%20of%20quarantined%20package.png) · [403 error](evidence/403%20on%20pull%20of%20quarantined%20package.png)

## 5. Limitations and Improvements

One thing I would improve that would be more inline with an actual production implementation of Cloudsmith was around me hardcoding the Cloudsmith index URL into each of my pip commands. I did this mostly for simplicities sake, but in the a real world scenario we wouldn't want developers to have to manually define each time. 

I imagine organizations would be able to enforce/implement this at different levels depending on their existing workflows, e.g. enforcing on the developer's workstations, or in their CI/CD pipelines. 

I also did run into some issues during the vulnerability quarantine policy where there seemed to be a delay between when the package was quarantined and when I started receiving a 403 when I would try to pull it. My guess is this is due to setting things up as Cache and Proxy vs Cache-Only but am curious to learn more about this. 

There were also a few instances where I was re-pulling certain application dependencies/container images that I presumed would have been cache hits but were showing as cache misses in the logs. Whether or not this is due to a misunderstanding on my part, something to do with using a trial license, or a misconfiguration... I'm not sure, but it's another area that piqued my interest. I ultimately decided to put to the side though since it didn't seem to be interfering with my ability to execute the remainder of the technical challenge.
