# The Directory Services Account (DSA)

The **DSA** in Microsoft Defender for Identity (**MDI**) is used for several critical functions including (but not limited to) the following:

<br/>

- &#128272; Connecting to the domain controller at startup.

- &#128272; Querying the domain controller for data on entities seen in network traffic, monitored events, and monitored ETW activities.

- &#128272; Requesting member lists for local administrator groups from devices via a **SAM-R** call.

- &#128272; Accessing the **DeletedObjects** container to collect information about deleted users and computers.

- &#128272; Domain and trust mapping, which occurs at sensor startup and every 10 minutes thereafter.

- &#128272; Querying another domain via LDAP for details when detecting activities from entities in those domains.

<br/>
<br/>
<br/>
<br/>

&#128273; A **DSA** is required for full security coverage in **MDI**. Without a **DSA**, you may expose your environment to certain risks, such as:

<br/>

- &#128549; Inability to fully monitor and analyze activities on your network, which could lead to undetected security breaches&#10071;

- &#128551; Lack of detailed information about deleted objects, which could be exploited by attackers to gain unauthorized access&#10071;

- &#128565; Insufficient data to calculate potential lateral movement paths, which are crucial for identifying compromised accounts and preventing further spread of an attack within the network&#10071;

<br/>
<br/>

&#9888; Not having a **DSA** in **MDI** can significantly limit the visibility and control over your network’s security, potentially leaving it **vulnerable to undetected attacks**. It’s recommended to configure a **DSA** for comprehensive protection&#10071;&#10071;&#10071;
