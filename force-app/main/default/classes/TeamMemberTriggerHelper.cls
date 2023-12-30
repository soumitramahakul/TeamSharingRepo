public with sharing class TeamMemberTriggerHelper implements Queueable{

    Map<id,Team_Member__c> teamMemberOldMap = new Map<Id,Team_Member__c>();
    Map<id,Team_Member__c> teamMemberNewMap = new Map<Id,Team_Member__c>();

    public TeamMemberTriggerHelper(Map<id,Team_Member__c> oldMap,Map<id,Team_Member__c> newMap){
        this.teamMemberOldMap = oldMap;
        this.teamMemberNewMap=newMap;
    }

    Public void execute(System.QueueableContext qc){

        list<GroupMember> grpMemberInsert = new list<GroupMember>();
        Map<Id,Id> userTeamMap = new Map<Id,Id>();
        Map<Id,Id> olduserTeamMap = new Map<Id,Id>();
        list<string> groupNames= new list<string>();
        List<SObject> sharesToDelete = new List<SObject>();
        Map<Id,Id> teamGroupIds = new Map<Id,Id>();

        if(teamMemberOldMap?.keySet()?.size()>0){
            for(id teamMember : teamMemberOldMap?.keySet()){
                if(teamMemberOldMap.get(teamMember)?.Team__c != teamMemberNewMap.get(teamMember).Team__c || teamMemberOldMap.get(teamMember)?.User__c != teamMemberNewMap.get(teamMember).User__c ){
                    userTeamMap.put(teamMemberNewMap.get(teamMember).User__c, teamMemberNewMap.get(teamMember).Team__c);
                    olduserTeamMap.put(teamMemberOldMap.get(teamMember).User__c,teamMemberOldMap.get(teamMember).Team__c);
                }
            }
        }
        else{
            for(Team_Member__c omember:teamMemberNewMap.values()){
                userTeamMap.put(teamMemberNewMap.get(omember.Id).User__c, teamMemberNewMap.get(omember.id).Team__c);
            }
        }
        //If teammmber has changed the team then remove the user from old Team group record
        if(olduserTeamMap?.keySet()?.size()>0){
            list<GroupMember> memberDelete =[Select Id,GroupId,UserOrGroupId from GroupMember where UserOrGroupId IN : olduserTeamMap.keySet()];
            if(memberDelete.size()>0){
                delete memberDelete;
            }
        }

        List<Team__c> teamList =[Select Id,Name,Application_To_Objects__c,Account__c,Account__r.Name from Team__c where Id IN :userTeamMap.values()];

        for (Team__c oTeam :teamList){
            string groupName=oTeam.Application_To_Objects__c+oteam.name+oteam.Account__r.Name;
            groupNames.add(groupName);
        }

        List<Group> grouplst= [Select Id,Name From Group Where Name IN :groupNames ];

        for(Team__c teams : teamList){
            for(Group groups : grouplst){
                if(teams.Application_To_Objects__c+teams.name+teams.Account__r.Name == groups.Name){
                    teamGroupIds.put(groups.id,teams.id);
                }
            }
        }

        for(id userId : userTeamMap.keySet()){
            for(id grpId :teamGroupIds.keySet()){
                if(userTeamMap.get(userId) == teamGroupIds.get(grpId)){
                    groupMember newGrpMember = new groupMember();
                    newGrpMember.groupId=grpId;
                    newGrpMember.UserOrGroupId = userId;
                    grpMemberInsert.add(newGrpMember);        
                }
            }
        }
        if(grpMemberInsert?.size()>0){
            insert grpMemberInsert;
        }
    }
}