public with sharing class TeamTriggerHelper {

    Public static void createGroup(Map<id,Team__C> oldMap,Map<id,Team__C> newMap){

        list<Group> grpToInsert = new List<Group>();
        list<string> grpNames = new List<string>();
        list<Team__C> teamlist = new List<Team__C>();
        list<string> availableToObject = new List<string>();
        list<Id> grpIds = new list<id>();
        List<Team__C> oldTeamLst= new List<Team__C>();
        set<Id> accountIds = new set<Id>();
        boolean isCreate = true;

        if(oldMap?.keySet()?.size()>0){
            for(id teamId : oldMap?.keySet()){
                if(oldMap.get(teamId)?.Account__c != newMap.get(teamId).Account__c){
                    teamlist.add(newMap.get(teamId));
                    oldTeamLst.add(oldMap.get(teamId));
                }if(oldMap.get(teamId)?.Account__c == newMap.get(teamId).Account__c && oldMap.get(teamId)?.Application_To_Objects__c == newMap.get(teamId).Application_To_Objects__c && oldMap.get(teamId)?.Type__c == newMap.get(teamId).Type__c){
                    isCreate= false;
                }
            }
        }
        else{
            teamlist.add(newMap.values());
        }
        //incase of Account change delete the old Group records
        if(oldTeamLst.size()>0 && isCreate){
            for (Team__C oldTeam : oldTeamLst){
                accountIds.add(oldTeam.Account__c);
            }
            List<Account> accList = [Select Id,name From Account where Id IN : accountIds WITH USER_MODE];
            for(Team__C oldTeam : oldTeamLst){
                for (Account oacc : accList){
                    if(oldTeam.Account__c == oacc.Id){
                        string grpname = oldTeam.Application_To_Objects__c+oldTeam.name+oacc.name;
                        grpNames.add(grpname);
                    }
                }
            }
            List<Group> groupToDelete = [Select Id,Name from Group Where Name IN : grpNames WITH USER_MODE];
            if(groupToDelete?.size()>0){
                delete groupToDelete;
            }
        }
        //Create Group
        for (Team__C oteam :[Select Id,Type__c,Application_To_Objects__c,Account__c,Name,Access_Level__c,Account__r.Name from Team__C where Id IN :newMap.keySet() WITH USER_MODE]){
            Group objGroup = new Group();
            objGroup.name = oteam.Application_To_Objects__c+oteam.name+oteam.Account__r.Name;
            objGroup.type='Regular';
            grpToInsert.add(objGroup);
        }
        if(grpToInsert?.size()>0 && isCreate){
            insert grpToInsert;
        }
    }
}