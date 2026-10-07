# Commerce Manifest

`scripts/catalog_drift.py` accepts loose JSON exports or normalized manifests.
Use this shape when creating a local fixture or comparison manifest:

```json
{
  "subscriptions": [
    {
      "productId": "com.example.pro.monthly",
      "referenceName": "Pro Monthly",
      "subscriptionGroupId": "pro",
      "subscriptionPeriod": "ONE_MONTH"
    }
  ],
  "iaps": [
    {
      "productId": "com.example.lifetime",
      "referenceName": "Lifetime",
      "type": "NON_CONSUMABLE"
    }
  ]
}
```

RevenueCat manifest:

```json
{
  "products": [
    {
      "store_identifier": "com.example.pro.monthly",
      "type": "subscription"
    },
    {
      "store_identifier": "com.example.lifetime",
      "type": "non_consumable"
    }
  ],
  "entitlements": [
    {
      "id": "pro",
      "products": ["com.example.pro.monthly", "com.example.lifetime"]
    }
  ],
  "offerings": [
    {
      "id": "default",
      "packages": [
        {
          "id": "$rc_monthly",
          "product_identifier": "com.example.pro.monthly"
        }
      ]
    }
  ]
}
```

Accepted aliases:

- App Store product ID: `productId`, `product_id`, `productID`, `identifier`,
  or `store_identifier`.
- RevenueCat store identifier: `store_identifier`, `storeIdentifier`,
  `productId`, `product_id`, or `identifier`.
- Product type: `type`, `productType`, `product_type`,
  `inAppPurchaseType`, or `kind`.

The script normalizes common App Store Connect type values such as
`CONSUMABLE`, `NON_CONSUMABLE`, `NON_RENEWING_SUBSCRIPTION`, and
`AUTO_RENEWABLE_SUBSCRIPTION`.
