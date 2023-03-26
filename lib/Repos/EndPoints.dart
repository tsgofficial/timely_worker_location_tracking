enum ENDPOINT { GET_LOCATION_DATA }

abstract class EndpointConfig {
  //http://sunday.dornodzar.mn/api/reset.phphttp://sunday.dornodzar.mn/api/sms_confirm.php

  static const String _host = "https://api.timely.mn";
  // static const String _httpPathConst = "/api/v2";

  static final Map<ENDPOINT, String> _ENDPOINTS = {
    ENDPOINT.GET_LOCATION_DATA: "/location/locationtrack",

    // https://admin.timely.mn/api/key-qr.php
  };

  static String getEnpoint(ENDPOINT endpoint) =>
      "$_host${_ENDPOINTS[endpoint]}";
}
