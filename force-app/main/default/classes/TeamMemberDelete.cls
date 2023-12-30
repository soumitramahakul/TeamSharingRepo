public with sharing class TeamMemberDelete implements Queueable {
    List<Team_Member__c> teamMemeberData = new List<Team_Member__c>();
    public TeamMemberDelete(list<Team_Member__c> memberLst){    
        this.teamMemeberData = memberLst;
    }

    public void execute(System.QueueableContext Qc){
        set<id> userIds = new set<id>();
        List<GroupMember> groupMemberList = new List<GroupMember>();
        for (Team_Member__c oMembers :teamMemeberData){
            userIds.add(oMembers.User__c);
        }
        if(userIds.size()>0){
            groupMemberList  = [ Select Id from GroupMember where UserOrGroupID in :userIds];
        }
        if(groupMemberList.size()>0){
            delete groupMemberList;
        }
    }
  
}