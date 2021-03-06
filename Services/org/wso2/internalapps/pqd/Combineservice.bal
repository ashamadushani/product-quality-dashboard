package org.wso2.internalapps.pqd;

import ballerina.net.http;
import ballerina.data.sql;
import ballerina.lang.jsons;
import ballerina.lang.errors;
import ballerina.utils.logger;
import ballerina.lang.messages;

struct ComponentRepo{
    string pqd_product_id;
    string pqd_component_name;
    string pqd_component_id;
    string pqd_github_repo_name;
}




@http:configuration {basePath:"/internal/product-quality/v1.0", httpsPort: 9092, keyStoreFile: "${ballerina.home}/bre/security/wso2carbon.jks", keyStorePass: "wso2carbon", certPass: "wso2carbon"}
service<http> ProductQualityService {

    @http:GET {}
    @http:Path {value:"/issues/all"}
    resource getAllIssues(message m){

        message response = {};

        json responseJson = {"error":false, "data":{ "items": [] }};

        json sonarAllJson = getAllAreaSonarIssues();
        json issuesAllJson = getIssuesData("all", 0, 0, 0);

        sql:Parameter[] paramsForArea = [];

        json allAreasJson = getDataFromDatabase(GET_GITHUB_AREA_QUERY, paramsForArea);

        int areaIndex = 0;

        while(areaIndex < lengthof allAreasJson) {

            json currentAreaIssuesJson = jsons:getJson(issuesAllJson, "$.data.items[?(@.id=="+ jsons:getInt(allAreasJson[areaIndex], "$.pqd_area_id") +
                                                                      ")].issues");

            int currentAreaIssues;

            if(lengthof currentAreaIssuesJson != 0){
                currentAreaIssues = jsons:getInt(currentAreaIssuesJson, "$[0]");
            }else{
                currentAreaIssues = 0;
            }


            json currentAreaSonarsJson = jsons:getJson(sonarAllJson, "$.data.items[?(@.id=="+ jsons:getInt(allAreasJson[areaIndex], "$.pqd_area_id") +
                                                                     ")].sonar");

            int currentAreaSonars;

            if(lengthof currentAreaSonarsJson != 0){
                currentAreaSonars = jsons:getInt(currentAreaSonarsJson, "$[0]");
            }else{
                currentAreaSonars = 0;
            }

            json currentAreaJson = {"name": jsons:getString(allAreasJson[areaIndex], "$.pqd_area_name"),
                                       "id": jsons:getInt(allAreasJson[areaIndex], "$.pqd_area_id"),
                                       "issues": currentAreaIssues, "sonar": currentAreaSonars
                                   };


            jsons:addToArray(responseJson, "$.data.items", currentAreaJson);

            areaIndex = areaIndex + 1;
        }


        json issueTypeIssues = jsons:getJson(issuesAllJson, "$.data.issueIssuetype");
        jsons:addToObject(responseJson, "$.data", "issueIssuetype", issueTypeIssues);

        json severityIssues = jsons:getJson(issuesAllJson, "$.data.issueSeverity");
        jsons:addToObject(responseJson, "$.data", "issueSeverity", severityIssues);


        json issueTypeSonars = jsons:getJson(sonarAllJson, "$.data.sonarIssuetype");
        jsons:addToObject(responseJson, "$.data", "sonarIssuetype", issueTypeSonars);

        json severitySonars = jsons:getJson(sonarAllJson, "$.data.sonarSeverity");
        jsons:addToObject(responseJson, "$.data", "sonarSeverity", severitySonars);


        messages:setJsonPayload(response, responseJson);

        messages:setHeader(response, "Access-Control-Allow-Origin", "*");

        messages:setHeader(response, "Access-Control-Allow-Methods", "GET, OPTIONS");

        reply response;

    }



    @http:GET {}
    @http:Path {value:"/issues/area/{areaId}"}
    resource getAllIssuesForArea(message m, @http:PathParam {value:"areaId"} int areaId){

        message response = {};

        json responseJson = {"error":false, "data":{ "items": [] }};

        json issuesAreaJson = getIssuesData("area", areaId, 0, 0);
        json sonarAreaJson = getSelectionResult("area", areaId, 0, 0);

        sql:Parameter areaIdParam = {sqlType:"integer", value:areaId};
        sql:Parameter[] paramsForAreaProduct = [areaIdParam];

        json allProductJson = getDataFromDatabase(GET_GITHUB_AREA_PRODUCT_QUERY, paramsForAreaProduct);

        int a = 0;

        while(a < lengthof allProductJson){

            json currentProductIssuesJson = jsons:getJson(issuesAreaJson, "$.data.items[?(@.id==" + jsons:getInt(allProductJson[a], "$.pqd_product_id") +
                                                                          ")].issues");
            int currentProductIssues;

            if(lengthof currentProductIssuesJson != 0) {
                currentProductIssues = jsons:getInt(currentProductIssuesJson, "$[0]");
            }else{
                currentProductIssues = 0;
            }


            json currentProductSonarsJson = jsons:getJson(sonarAreaJson, "$.data.items[?(@.id==" + jsons:getInt(allProductJson[a], "$.pqd_product_id") +
                                                                         ")].sonar");

            int currentProductSonars;

            if(lengthof currentProductSonarsJson != 0) {
                currentProductSonars = jsons:getInt(currentProductSonarsJson, "$[0]");
            }else{
                currentProductSonars = 0;
            }

            json currentProductJson = {"name":jsons:getString(allProductJson[a], "$.pqd_product_name"),
                                          "id": jsons:getInt(allProductJson[a], "$.pqd_product_id"),
                                          "issues": currentProductIssues, "sonar": currentProductSonars
                                      };


            jsons:addToArray(responseJson, "$.data.items", currentProductJson);

            a = a + 1;
        }


        json issueTypeIssues = jsons:getJson(issuesAreaJson, "$.data.issueIssuetype");
        jsons:addToObject(responseJson, "$.data", "issueIssuetype", issueTypeIssues);

        json severityIssues = jsons:getJson(issuesAreaJson, "$.data.issueSeverity");
        jsons:addToObject(responseJson, "$.data", "issueSeverity", severityIssues);


        json issueTypeSonars = jsons:getJson(sonarAreaJson, "$.data.sonarIssuetype");
        jsons:addToObject(responseJson, "$.data", "sonarIssuetype", issueTypeSonars);

        json severitySonars = jsons:getJson(sonarAreaJson, "$.data.sonarSeverity");
        jsons:addToObject(responseJson, "$.data", "sonarSeverity", severitySonars);


        messages:setJsonPayload(response, responseJson);

        messages:setHeader(response, "Access-Control-Allow-Origin", "*");

        messages:setHeader(response, "Access-Control-Allow-Methods", "GET, OPTIONS");

        reply response;

    }

    @http:GET {}
    @http:Path {value:"/issues/product/{productId}"}
    resource getAllIssuesForProduct(message m,
                                    @http:PathParam{value:"productId"} int productId){

        message response = {};

        json responseJson = {"error":false, "data":{ "items": [] }};

        json issuesProductJson = getIssuesData("product", productId, 0, 0);
        json sonarProductJson = getSelectionResult("product", productId, 0, 0);

        sql:Parameter productIdParam = {sqlType:"integer", value:productId};
        sql:Parameter[] paramsForProductComponent = [productIdParam];

        json allComponentJson = getDataFromDatabase(GET_GITHUB_PRODUCT_COMPONENT_QUERY, paramsForProductComponent);

        int a = 0;

        while(a < lengthof allComponentJson){

            int currentComponentId = jsons:getInt(allComponentJson[a], "$.pqd_component_id");
            json currentComponentIssuesJson;

            currentComponentIssuesJson = jsons:getJson(issuesProductJson, "$.data.items[?(@.id==" +  currentComponentId +
                                                                          ")].issues");


            int currentComponentIssues;

            if(lengthof currentComponentIssuesJson != 0) {
                currentComponentIssues = jsons:getInt(currentComponentIssuesJson, "$[0]");
            }else{
                currentComponentIssues = 0;
            }


            json currentComponentSonarsJson = jsons:getJson(sonarProductJson, "$.data.items[?(@.id==" + jsons:getInt(allComponentJson[a], "$.pqd_component_id") +
                                                                              ")].sonar");

            int currentComponentSonars;

            if(lengthof currentComponentSonarsJson != 0) {
                currentComponentSonars = jsons:getInt(currentComponentSonarsJson, "$[0]");
            }else{
                currentComponentSonars = 0;
            }

            json currentComponentJson = {"name":jsons:getString(allComponentJson[a], "$.pqd_component_name"),
                                            "id": currentComponentId,
                                            "issues": currentComponentIssues, "sonar": currentComponentSonars
                                        };


            jsons:addToArray(responseJson, "$.data.items", currentComponentJson);

            a = a + 1;
        }


        json issueTypeIssues = jsons:getJson(issuesProductJson, "$.data.issueIssuetype");
        jsons:addToObject(responseJson, "$.data", "issueIssuetype", issueTypeIssues);

        json severityIssues = jsons:getJson(issuesProductJson, "$.data.issueSeverity");
        jsons:addToObject(responseJson, "$.data", "issueSeverity", severityIssues);


        json issueTypeSonars = jsons:getJson(sonarProductJson, "$.data.sonarIssuetype");
        jsons:addToObject(responseJson, "$.data", "sonarIssuetype", issueTypeSonars);

        json severitySonars = jsons:getJson(sonarProductJson, "$.data.sonarSeverity");
        jsons:addToObject(responseJson, "$.data", "sonarSeverity", severitySonars);


        messages:setJsonPayload(response, responseJson);

        messages:setHeader(response, "Access-Control-Allow-Origin", "*");

        messages:setHeader(response, "Access-Control-Allow-Methods", "GET, OPTIONS");

        reply response;

    }

    @http:GET {}
    @http:Path {value:"/issues/component/{componentId}"}
    resource getAllIssuesForComponent(message m,
                                      @http:PathParam{value:"componentId"} int componentId){

        message response = {};


        sql:Parameter paramForComponentId = {sqlType:"integer", value: componentId};
        sql:Parameter[] paramsForComponent = [paramForComponentId];

        json productIdJson = getDataFromDatabase(GET_PRODUCT_ID_FOR_COMPONENT_ID, paramsForComponent);

        int productId = 0;

        if (lengthof productIdJson > 0){
            productId = jsons:getInt(productIdJson, "$[0].pqd_product_id");
        } else {
            json responseJson = {"error":true, "data":{"items": [], "issueIssuetype":[], "issueSeverity":[]}};
        }

        json responseJson = {"error":false, "data":{ "items": [] }};

        sql:Parameter paramForProduct = {sqlType: "integer", value:productId};
        sql:Parameter[] paramsForProduct = [paramForProduct];

        json issuesComponentJson = getIssuesData("component", componentId, 0, 0);
        json sonarComponentJson = getSelectionResult("component", componentId, 0, 0);




        json allComponentJson = getDataFromDatabase(GET_GITHUB_PRODUCT_COMPONENT_QUERY, paramsForProduct);

        int a = 0;

        while(a < lengthof allComponentJson){

            int currentComponentId = jsons:getInt(allComponentJson[a], "$.pqd_component_id");
            json currentComponentIssuesJson;

            currentComponentIssuesJson = jsons:getJson(issuesComponentJson, "$.data.items[?(@.id==" +  currentComponentId +
                                                                            ")].issues");

            int currentComponentIssues;

            if(lengthof currentComponentIssuesJson != 0) {
                currentComponentIssues = jsons:getInt(currentComponentIssuesJson, "$[0]");
            }else {
                currentComponentIssues = 0;
            }


            json currentComponentSonarsJson = jsons:getJson(sonarComponentJson, "$.data.items[?(@.id==" + jsons:getInt(allComponentJson[a], "$.pqd_component_id") +
                                                                                ")].sonar");

            int currentComponentSonars;

            if(lengthof currentComponentSonarsJson != 0) {
                currentComponentSonars = jsons:getInt(currentComponentSonarsJson, "$[0]");
            }else{
                currentComponentSonars = 0;
            }

            json currentComponentJson = {"name":jsons:getString(allComponentJson[a], "$.pqd_component_name"),
                                            "id": currentComponentId,
                                            "issues": currentComponentIssues, "sonar": currentComponentSonars
                                        };


            jsons:addToArray(responseJson, "$.data.items", currentComponentJson);

            a = a + 1;
        }

        json issueTypeIssues = jsons:getJson(issuesComponentJson, "$.data.issueIssuetype");
        jsons:addToObject(responseJson, "$.data", "issueIssuetype", issueTypeIssues);

        json severityIssues = jsons:getJson(issuesComponentJson, "$.data.issueSeverity");
        jsons:addToObject(responseJson, "$.data", "issueSeverity", severityIssues);


        json issueTypeSonars = jsons:getJson(sonarComponentJson, "$.data.sonarIssuetype");
        jsons:addToObject(responseJson, "$.data", "sonarIssuetype", issueTypeSonars);

        json severitySonars = jsons:getJson(sonarComponentJson, "$.data.sonarSeverity");
        jsons:addToObject(responseJson, "$.data", "sonarSeverity", severitySonars);


        messages:setJsonPayload(response, responseJson);

        messages:setHeader(response, "Access-Control-Allow-Origin", "*");

        messages:setHeader(response, "Access-Control-Allow-Methods", "GET, OPTIONS");

        reply response;

    }

    @http:GET {}
    @http:Path {value:"/getIssueTypesAndSeverities"}
    resource getIssueTypesAndSeverities(message m) {

        message response = {};
        json data = getIssueTypesAndSeverities();
        messages:setJsonPayload(response, data);
        messages:setHeader(response, "Access-Control-Allow-Origin", "*");
        messages:setHeader(response, "Access-Control-Allow-Methods", "GET, OPTIONS");
        reply response;
    }
}


function getSQLconfigData(json configData)(map){

    string dbName;
    string dbHost;
    int dbPort;
    string dbUsername;
    string dbPassword;
    int maxPoolConnections;

    try {
        dbHost = jsons:getString(configData, "$.PQD_JDBC.DB_HOST");
        dbPort = jsons:getInt(configData, "$.PQD_JDBC.DB_PORT");
        dbName = jsons:getString(configData, "$.PQD_JDBC.DB_NAME");
        dbUsername = jsons:getString(configData, "$.PQD_JDBC.DB_USERNAME");
        dbPassword = jsons:getString(configData, "$.PQD_JDBC.DB_PASSWORD");
        maxPoolConnections = jsons:getInt(configData, "PQD_JDBC.MAXIMUM_POOL_SIZE");

    } catch (errors:Error err) {
        logger:error("Properties not defined in config.json: " + err.msg );
        dbHost = jsons:getString(configData, "$.PQD_JDBC.DB_HOST");
        dbPort = jsons:getInt(configData, "$.PQD_JDBC.DB_PORT");
        dbName = jsons:getString(configData, "$.PQD_JDBC.DB_NAME");
        dbUsername = jsons:getString(configData, "$.PQD_JDBC.DB_USERNAME");
        dbPassword = jsons:getString(configData, "$.PQD_JDBC.DB_PASSWORD");
        maxPoolConnections = jsons:getInt(configData, "PQD_JDBC.MAXIMUM_POOL_SIZE");

    }

    string jdbcUrl = "jdbc:mysql://" + dbHost + ":" + dbPort + "/" + dbName;

    map propertiesMap = {"jdbcUrl": jdbcUrl,"username": dbUsername, "password": dbPassword, "maximumPoolSize":maxPoolConnections};
    return propertiesMap;

}

function getIssueTypesAndSeverities()(json){
    json data = {"error":false};
    json info = {issueIssuetypes:[], issueSeverities:[], sonarIssuetypes:[{"id":1, "type":"Bug"},
                                                                          {"id":2, "type":"Code smell"},
                                                                          {"id":3, "type":"Vulnerability"}],
                    sonarSeverities:[{"id":1, "severity":"Blocker"},{"id":2, "severity":"Critical"},{"id":3, "severity":"Major"},
                                     {"id":4, "severity":"Minor"},{"id":5, "severity":"Info"}]};


    sql:Parameter[] params = [];

    json issuetypes = getDataFromDatabase(GET_ALL_ISSUE_TYPE_DB_QUERY_VERSION2, params);
    json severities = getDataFromDatabase(GET_SEVERITY_DB_QUERY_VERSION2, params);

    jsons:addToObject(info,"$","issueIssuetypes" ,issuetypes);
    jsons:addToObject(info,"$","issueSeverities", severities);

    jsons:addToObject(data, "$", "data", info);
    return data;
}

function createIssuesDBcon()(sql:ClientConnector){
    map sqlProperties = getSQLconfigData(configData);
    sql:ClientConnector issuesDBcon = create sql:ClientConnector(sqlProperties);
    return issuesDBcon;
}


