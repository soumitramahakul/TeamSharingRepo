public with sharing class GenericGroupDelete implements Queueable  {
    private Map<Id,Team__c> objectData;

    public GenericGroupDelete(Map<Id,Team__c> data){
        this.objectData = data;
    }

    public void execute(System.QueueableContext qc){

        List<String> groupNames = new List<string>();
        set<Id> teamIds = new set<Id>();

        system.debug('Team Id: ' + objectData);

        for (Team__c oTeam : [Select Id,Type__c,Application_To_Objects__c,Account__c,Name,Access_Level__c,Account__r.Name from Team__C where Id IN :objectData.keySet() ALL ROWS]){
            string groupName=oteam.Application_To_Objects__c+oteam.name+oteam.Account__r.Name;
            groupNames.add(groupName);
        }
        list<Group> groupsToDelete = [Select Id,Name From Group Where Name IN :groupNames ];

        if(groupsToDelete?.size()>0){
            delete groupsToDelete;
        }
    }
}