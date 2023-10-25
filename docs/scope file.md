# selectiong the scope for your deployment

DELETE




Selecting a scope for your deployment should be a simple task, but it is not. atleast from a programming perspective. Remember, BADU is not supposed to add to the complexity of your deployment, it is supposed to make it easier. so we have to be creative:

these are merly suggestions of how it is implemented as of now, and it might change in the future, but i will mark the options that would be most likely be kept in the future.

if you want to select scope for your particular deployment, you have 3 options:

1. do nothing. if no options are selected, i will assume its a subscription deployment

2. have a bicep file inside the folder with the correct [targetscope](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-to-resource-group?tabs=azure-cli) appended at the top. this is always neccecary for  (This will most likely be the option that is kept in the future)
   1. this would be a bicep file with the following at the top:
   2. `targetScope = 'subscription'`
   3. `targetScope = 'resourceGroup'`
   4. `targetScope = 'managementGroup'`
   5. `targetScope = 'tenant'`