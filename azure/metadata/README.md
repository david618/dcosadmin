# Azure Metadata Service

Some info about [Azure Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service)


## Get Instance Info using Curl

```curl -H Metadata:true http://169.254.169.254/metadata/instance```

This returns info like:

```
{
  "compute": {
    "location": "westus2",
    "name": "sfoss47boot",
    "offer": "CentOS",
    "osType": "Linux",
    "placementGroupId": "",
    "platformFaultDomain": "0",
    "platformUpdateDomain": "0",
    "publisher": "OpenLogic",
    "resourceGroupName": "SFOSS47",
    "sku": "7.4",
    "subscriptionId": "42e12bff-9125-4a9a-987d-685e9c480b0a",
    "tags": "",
    "version": "7.4.20180118",
    "vmId": "5d330f84-1f55-4877-9d7d-2adea42bb8b2",
    "vmSize": "Standard_D1_V2"
  },
  "network": {
    "interface": [
      {
        "ipv4": {
          "ipAddress": [
            {
              "privateIpAddress": "172.17.0.4",
              "publicIpAddress": "52.175.246.17"
            }
          ],
          "subnet": [
            {
              "address": "172.17.0.0",
              "prefix": "24"
            }
          ]
        },
        "ipv6": {
          "ipAddress": []
        },
        "macAddress": "000D3AFD5ED0"
      }
    ]
  }
}
```

You could use jq to pull out a specific element.  For example:

To return the Resource Group Name:

```curl -s -H Metadata:true http://169.254.169.254/metadata/instance?api-version=2017-08-01 | jq .compute.resourceGroupName```




