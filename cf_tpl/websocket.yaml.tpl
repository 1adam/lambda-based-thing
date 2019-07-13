AWSTemplateFormatVersion: "2010-09-09"
Transform: AWS::Serverless-2016-10-31
Description: >
  recycling "simple-websockets-chat-app"
Parameters:
  TableName:
    Type: String
    Default: 'websocket_conns'
    Description: (Required) The name of the new DynamoDB to store connection identifiers for each connected clients. Minimum 3 characters
    MinLength: 3
    MaxLength: 50
    AllowedPattern: ^[A-Za-z_]+$
    ConstraintDescription: 'Required. Can be characters and underscore only. No numbers or special characters allowed.'

Resources:
  SimpleWebSocket:
    Type: AWS::ApiGatewayV2::Api
    Properties:
      Name: SimpleWebSocket
      ProtocolType: WEBSOCKET
      RouteSelectionExpression: "$request.body.action"
  ConnectRoute:
    Type: AWS::ApiGatewayV2::Route
    Properties:
      ApiId: !Ref SimpleWebSocket
      RouteKey: $connect
      AuthorizationType: NONE
      OperationName: ConnectRoute
      Target: !Join
        - '/'
        - - 'integrations'
          - !Ref ConnectInteg
  ConnectInteg:
    Type: AWS::ApiGatewayV2::Integration
    Properties:
      ApiId: !Ref SimpleWebSocket
      Description: Connect Integration
      IntegrationType: AWS_PROXY
      IntegrationUri: 
        Fn::Sub:
            arn:aws:apigateway:$${AWS::Region}:lambda:path/2015-03-31/functions/$${OnConnectFunction.Arn}/invocations
  DisconnectRoute:
    Type: AWS::ApiGatewayV2::Route
    Properties:
      ApiId: !Ref SimpleWebSocket
      RouteKey: $disconnect
      AuthorizationType: NONE
      OperationName: DisconnectRoute
      Target: !Join
        - '/'
        - - 'integrations'
          - !Ref DisconnectInteg
  DisconnectInteg:
    Type: AWS::ApiGatewayV2::Integration
    Properties:
      ApiId: !Ref SimpleWebSocket
      Description: Disconnect Integration
      IntegrationType: AWS_PROXY
      IntegrationUri: 
        Fn::Sub:
            arn:aws:apigateway:$${AWS::Region}:lambda:path/2015-03-31/functions/$${OnDisconnectFunction.Arn}/invocations
  SendRoute:
    Type: AWS::ApiGatewayV2::Route
    Properties:
      ApiId: !Ref SimpleWebSocket
      RouteKey: sendaction
      AuthorizationType: NONE
      OperationName: SendRoute
      Target: !Join
        - '/'
        - - 'integrations'
          - !Ref SendInteg
  SendInteg:
    Type: AWS::ApiGatewayV2::Integration
    Properties:
      ApiId: !Ref SimpleWebSocket
      Description: Send Integration
      IntegrationType: AWS_PROXY
      IntegrationUri: 
        Fn::Sub:
            arn:aws:apigateway:$${AWS::Region}:lambda:path/2015-03-31/functions/$${SendActionFunction.Arn}/invocations
  Deployment:
    Type: AWS::ApiGatewayV2::Deployment
    DependsOn:
    - ConnectRoute
    - SendRoute
    - DisconnectRoute
    Properties:
      ApiId: !Ref SimpleWebSocket
  Stage:
    Type: AWS::ApiGatewayV2::Stage
    Properties:
      StageName: think
      Description: thinking stage
      DeploymentId: !Ref Deployment
      ApiId: !Ref SimpleWebSocket
  ConnectionsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      AttributeDefinitions:
      - AttributeName: "connectionId"
        AttributeType: "S"
      KeySchema:
      - AttributeName: "connectionId"
        KeyType: "HASH"
      ProvisionedThroughput:
        ReadCapacityUnits: 5
        WriteCapacityUnits: 5
      SSESpecification:
        SSEEnabled: True
      TableName: !Ref TableName
  OnConnectFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: s3://${s3_bucket}/${conn_key}
      Handler: app.handler
      MemorySize: 256
      Runtime: nodejs10.x
      Environment:
        Variables:
          TABLE_NAME: !Ref TableName
      Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref TableName
  OnConnectPermission:
    Type: AWS::Lambda::Permission
    DependsOn:
      - SimpleWebSocket
      - OnConnectFunction
    Properties:
      Action: lambda:InvokeFunction
      FunctionName: !Ref OnConnectFunction
      Principal: apigateway.amazonaws.com
  OnDisconnectFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: s3://${s3_bucket}/${disconn_key}
      Handler: app.handler
      MemorySize: 256
      Runtime: nodejs10.x
      Environment:
        Variables:
          TABLE_NAME: !Ref TableName
      Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref TableName
  OnDisconnectPermission:
    Type: AWS::Lambda::Permission
    DependsOn:
      - SimpleWebSocket
      - OnDisconnectFunction
    Properties:
      Action: lambda:InvokeFunction
      FunctionName: !Ref OnDisconnectFunction
      Principal: apigateway.amazonaws.com
  SendActionFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: s3://${s3_bucket}/${act_key}
      Handler: app.handler
      MemorySize: 256
      Runtime: nodejs10.x
      Environment:
        Variables:
          TABLE_NAME: !Ref TableName
      Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref TableName
      - Statement:
        - Effect: Allow
          Action:
          - 'execute-api:ManageConnections'
          Resource:
          - !Sub 'arn:aws:execute-api:$${AWS::Region}:$${AWS::AccountId}:$${SimpleWebSocket}/*'
  SendActionPermission:
    Type: AWS::Lambda::Permission
    DependsOn:
      - SimpleWebSocket
      - SendActionFunction
    Properties:
      Action: lambda:InvokeFunction
      FunctionName: !Ref SendActionFunction
      Principal: apigateway.amazonaws.com

Outputs:
  ConnectionsTableArn:
    Description: "Connections table ARN"
    Value: !GetAtt ConnectionsTable.Arn

  OnConnectFunctionArn:
    Description: "OnConnect function ARN"
    Value: !GetAtt OnConnectFunction.Arn

  OnDisconnectFunctionArn:
    Description: "OnDisconnect function ARN"
    Value: !GetAtt OnDisconnectFunction.Arn

  SendActionFunctionArn:
    Description: "SendAction function ARN"
    Value: !GetAtt SendActionFunction.Arn

  WebSocketURI:
    Description: "The WSS Protocol URI to connect to"
    Value: !Join [ '', [ 'wss://', !Ref SimpleWebSocket, '.execute-api.',!Ref 'AWS::Region','.amazonaws.com/',!Ref 'Stage'] ]