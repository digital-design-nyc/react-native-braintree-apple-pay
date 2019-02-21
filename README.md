
# react-native-braintree-apple-pay

## Getting started

Run 

`$ npm install react-native-braintree-apple-pay --save`

or

`$ yarn add react-native-braintree-apple-pay`

for adding package.

### Mostly automatic installation

`$ react-native link react-native-braintree-apple-pay`


#### iOS specific

You must have a iOS deployment target >= 9.0.

If you don't have a Podfile or are unsure on how to proceed, see the CocoaPods usage guide.

In your `Podfile`, add:

```
pod 'Braintree'
pod 'Braintree/Apple-Pay'
pod 'Braintree/DataCollector'
```

Then:

```
cd ios
pod repo update # optional and can be very long
pod install
```

## Usage
```javascript
import RNBraintreeApplePay from 'react-native-braintree-apple-pay';

...

<Button
  title='Press it'
  onPress={() => {
    RNBraintreeApplePay.show({
      clientToken: 'your_client_token',
      merchantIdentifier: 'merchant_identifier',
      countryCode: 'US',
      currencyCode: 'USD',
      merchantName: 'MerchantCompany',
      orderTotal: '10',
    })
      .then(console.log)
      .catch(console.log)
  }}
/>
...

```
  
