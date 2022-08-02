___INFO___

{
  "type": "CLIENT",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Copia de GA4 stream enricher",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "A custom client template to enrich your GA4 hits with external sources.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "ga4Param",
    "displayName": "Claim GA4 requests that include the following key:",
    "simpleValueType": true,
    "help": "Incoming GA4 requests must contain this param within their payload for this client to claim it",
    "valueValidators": [
      {
        "type": "NON_EMPTY",
        "errorMessage": "Please enter the name of the param the GA4 hit must contain for this client to claim it."
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "origin",
    "displayName": "Origin of the incoming request",
    "simpleValueType": true,
    "valueHint": "https://yourwebsite.net",
    "valueValidators": [
      {
        "type": "NON_EMPTY",
        "errorMessage": "Cannot leave this field empty."
      },
      {
        "type": "REGEX",
        "args": [
          "^https\\:\\/\\/.+(\\.(com|es|net|dev|org))$"
        ],
        "errorMessage": "Endpoint must begin with \u0027https://\u0027"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "endpoint",
    "displayName": "Endpoint where enriching JSON is hosted",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "REGEX",
        "args": [
          "^https\\:\\/\\/.+(\\.(com|es|net|dev|org))\\/.*"
        ],
        "enablingConditions": [],
        "errorMessage": "You must enter a valid endpoint. Must start with \u0027https://\u0027 and contain a valid domain extension."
      },
      {
        "type": "NON_EMPTY",
        "errorMessage": "You must enter a valid endpoint. Must start with \u0027https://\u0027 and contain a valid domain extension."
      }
    ],
    "valueHint": "https://yourendpoint.com/path"
  },
  {
    "type": "CHECKBOX",
    "name": "apiAuthentication",
    "checkboxText": "Authentication required to call this API?",
    "simpleValueType": true,
    "help": "Only support Bearer authentication",
    "subParams": [
      {
        "type": "TEXT",
        "name": "bearerToken",
        "displayName": "Bearer Token",
        "simpleValueType": true,
        "enablingConditions": [
          {
            "paramName": "apiAuthentication",
            "paramValue": true,
            "type": "EQUALS"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

//API's required for this client to work
const claimRequest = require('claimRequest');
const getRequestQueryParameter = require('getRequestQueryParameter');
const runContainer = require('runContainer');
const sendHttpGet = require('sendHttpGet');
const getRequestHeader = require('getRequestHeader');
const isRequestMpv2 = require('isRequestMpv2');
const extractEventsFromMpv2 = require('extractEventsFromMpv2');
const returnResponse = require('returnResponse');
const JSON = require('JSON');
const Object = require('Object');


const hostedJsonQueryString = getRequestQueryParameter('ep.'+ data.ga4Param);
const origin = getRequestHeader('Origin');

//Declare enrichGa4Stream variable and set it to false by default
let enrichGa4Stream = false;

//Generate an array with the GA4 hit params, doesn't matter if GET or POST request
const ga4EventParams = extractEventsFromMpv2();

//Declare eventObject variable
let eventObject;

//Populate the eventObject variable with the object contained in the ga4EventParams array
for(let i = 0; i < ga4EventParams.length; i++){
    
    eventObject = ga4EventParams[i];
      
}
      
//Generate an array with the keys contained in the eventObject object
const eventsKeys = Object.keys(eventObject);

//Run a for loop against the eventsKey array to look for the data.ga4Param    
for(var i = 0 ; i < eventsKeys.length ; i++){
    //Does the eventsKeys array contain the value of template field data.ga4Params? If 'yes', set enrichGa4Stream variable to true
    if(eventsKeys[i] === data.ga4Param){
          
        enrichGa4Stream = true;
          
    }
        
}

//Claim incoming request if all these conditions are met 
if(origin === data.origin && isRequestMpv2() && enrichGa4Stream === true ){

    claimRequest();
   
    //Variable containing the url to which the request is going to be sent
    const requestUrl = data.endpoint;
  
    //Necessary request headers  
    const requestHeaders = function(){
      //If endpoint requires authentication...
      if(data.apiAuthentication){
  
        return {
          headers: {'content-Type':'application/json', 'Authorization':'Bearer ' + data.bearerToken}
        }; 
    
      } 
      //...and if it doesn't
      else {
    
        return {
          headers: {'content-Type' : 'application/json'}
        };    
    
      }
  
    };

   //GET request that returns a promise: the server hosted dataLayer
  sendHttpGet(requestUrl,requestHeaders()).then((results => {
    
    //If promise comes back with a succesful response...  
    if(results.statusCode === 200){
    
    const dataLayer = JSON.parse(results.body);
    const dataLayerKeys = Object.keys(dataLayer);
    const dataLayerValues = Object.values(dataLayer);

    for(let i = 0; i < dataLayerKeys.length; i++){
      
    //If eventObject and dataLayer objects don't have keys that are named the same...
      
      if(!eventObject.hasOwnProperty(dataLayerKeys[i])){
    
      eventObject[dataLayerKeys[i]] = dataLayerValues[i];
      
      }
      //Otherwise, rename the property to be added to the already existing evenObject object concatenating a _ at the end
      else{
      
        let renamedKey = dataLayerKeys[i] + '_';
        eventObject[renamedKey] = dataLayerValues[i];
      
      }
          
    }
    
   //Run container  with eventObject 
   runContainer(eventObject, () => returnResponse());
   }
    
   //If promise comes back with a response other than 200, run a virtual instance of the container with the GA4 event data object alone
    
   else{
   
   runContainer(eventObject, () => returnResponse());
   
   }

  }));
   
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "queryParametersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "bodyAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "headersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "pathAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "run_container",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "return_response",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 2/8/2022, 21:20:22


