public with sharing class Generic_SobjectSharing implements Queueable{
    private list<sObject> objectData;
    private Map<id,case> oldCase;
    // Cnstructor to take the List of sObject Records from Trigger
    public Generic_SobjectSharing(list<sObject> data,Map<id,case> oldCases){
        this.objectData = data;
        this.oldCase=oldCases;
        system.debug('Data , '+ this.objectData);
    }
    public void execute(System.QueueableContext qc) {
        string accuntid;
        string typeField;
        String sObjName;
        string shareObject;
        string strAccessLevel;
        string strRowCause;
        string accessLevel;
        SObjectType objectType;
        Boolean isCustom;
        Schema.DescribeSObjectResult objDescribe;

        map<string,string> objectMap = new Map<string,string> ();
        map<id,id> teamGroupMap = new Map<id,id>();
        Map<Id,list<id>> teamUserMap = new Map<Id,list<id>>();
        Map<Id,Id> caseTeamMap =    new Map<Id,id>();
        
        List<Team__c> teamRecords = new List<Team__c>();
        List<Group> groupId = new List<Group>();
        list<Id> userList = new list<Id>();
        list<string> grpName = new list<string>();
        list<SObject> lstObjects = new list<SObject>();
        list<List<SObject>> shareRecords = new list<List<SObject>>();
        list<SObject> shareRecordToUpdate = new list<SObject>();
        list<Id> caseTeamId = new List<Id>();

        set<id> objectIdSet= new set<id>();
   

        if(objectData.size()>0 && objectData!=null){
            sObjName = this.objectData[0]?.getSObjectType().getDescribe().getName();
            objectType = Schema.getGlobalDescribe().get(sObjName);
            objDescribe = objectType.getDescribe();
            isCustom=objDescribe?.isCustom();
        }else{
            return ;
        }

        list<Object_Sharing__mdt> objectMappings = [SELECT MasterLabel,Objects__c, DeveloperName,Delete_old_Sharing__c,Sharing_Reason__c,Access_Level__c ,Type_of_Sharing__c,Type__c,Account__c,Delete_Sharing_Class__c FROM Object_Sharing__mdt Where Objects__c =: sObjName];

        for(SObject data:objectData){
            accuntid =string.valueOf(data.get(objectMappings[0]?.Account__c));
            typeField =string.valueOf(data.get(objectMappings[0]?.Type__c));
            objectMap.put(accuntid,typeField);
            objectIdSet.add(data.id);
            if(String.isNotBlank(string.valueOf(data.get('Team__c')))){
                caseTeamId.add(Id.valueOf(string.valueOf(data.get('Team__c'))));
            }
        }

        //Delete old Sharing Recors
        if(!isCustom && objectMappings.size()>0 && objectMappings[0]?.Delete_old_Sharing__c == true && objectMappings[0]?.Delete_Sharing_Class__c !=null ){
            string className=objectMappings[0]?.Delete_Sharing_Class__c;
            Type classType =Type.forName(className);
            DeleteSharing deleteClass=(DeleteSharing)classType.newInstance();
            deleteClass.deleteShareRecords(objectIdSet,''); 
        }
        else if (isCustom && objectMappings.size()>0){
            //deleteOldShareRecords(objectIdSet,objectMappings[0]?.Sharing_Reason__c);
            string className=objectMappings[0]?.Delete_Sharing_Class__c;
            Type classType =Type.forName(className);
            DeleteSharing deleteClass=(DeleteSharing)classType.newInstance();
            deleteClass.deleteShareRecords(objectIdSet,objectMappings[0]?.Sharing_Reason__c); 
        }
        if(caseTeamId.size()>0){
        teamRecords =  [SELECT Id,Name,Application_To_Objects__c,Access_Level__c,Account__c,Account__r.Name,Type__c,(SELECT Id,Team__c,User__c FROM Team_Members__r) 
                        FROM Team__c WHERE ID IN :caseTeamId];
        }else{
        teamRecords =  [SELECT Id,Name,Application_To_Objects__c,Access_Level__c,Account__c,Account__r.Name,Type__c,(SELECT Id,Team__c,User__c FROM Team_Members__r) 
                        FROM Team__c WHERE Type__c IN :objectMap.values() AND Account__c IN :objectMap.keySet() AND Default__c=true]; // Query to get the teams based on AccountId & Type
        }

        if(teamRecords?.size() >0 && objectMappings[0]?.Type_of_Sharing__c=='Group'){
            for(Team__c oteam:teamRecords){
                string strName= sObjName+oteam.Name+oteam.Account__r.Name;
                grpName.add(strName); 
            }                                                  
            groupId = [Select Id,Name from Group Where Name IN :grpName];  
        }
        else{
            for(Team__c oteam:teamRecords){
                for(Team_Member__c oteamMember:oTeam.Team_Members__r){
                    if(oTeam.id==oteamMember.Team__c){
                        userList.add(oteamMember.User__c);
                        teamUserMap.put(oTeam.id,userList);
                    }
                }
            }
        }

        for (Group oGroup : groupId){
            for(Team__c oteam:teamRecords){
                if(sObjName+oteam.Name+oteam.Account__r.Name == oGroup.Name){
                    teamGroupMap.put(oteam.id,oGroup.id);
                }
            }
        }
                
        
        //   the Object Records Team field
        if(teamRecords?.size() >0){
            for(SObject data:objectData){
                for(Team__c oTeam:teamRecords){
                    if(data.get(objectMappings[0]?.Account__c) == oTeam.Account__c && data.get(objectMappings[0]?.Type__c) == oTeam.Type__c){
                        SObject shareRecord = objectType.newsObject();
                        shareRecord.put('Id',data.id);
                        shareRecord.put('Team__c',oTeam.id);
                        lstObjects.add(shareRecord);
                        caseTeamMap.put(data.id,oTeam.id);
                    }
                }
            }
        }

        if(!lstObjects.isEmpty()){
            system.debug('List of team'+JSON.serializePretty(lstObjects));
            update lstObjects; 
        }                     
       

        //Verifying if the SObject is a custom object or not
        if(String.isNotBlank(sObjName)){
            for(Team__c oteam:teamRecords) {
                string parentField;
                string strAccessLevelFieldName;
                if(isCustom){
                    string objStrName=String.valueOf(sObjName);
                    shareObject =objStrName.replace('__c','__Share');
                    parentField='ParentId';
                    strAccessLevelFieldName='AccessLevel';
                    strAccessLevel=!String.isBlank(oteam.Access_Level__c) ? oteam.Access_Level__c :objectMappings.size()>0 ?objectMappings[0].Access_Level__c : 'Read'; 
                    strRowCause='';
                }
                else{
                    shareObject=String.valueOf(sObjName)+'Share';
                    parentField=sObjName+'Id';
                    strAccessLevelFieldName='CaseAccessLevel';
                    strAccessLevel=!String.isBlank(oteam.Access_Level__c) ? oteam.Access_Level__c :objectMappings.size()>0 ?objectMappings[0].Access_Level__c : 'Read';
                    strRowCause='Manual';
                }
                if(objectMappings[0]?.Type_of_Sharing__c=='Group' && groupId?.size()>0){
                    shareRecords.add(createShareRecords(objectMappings[0],caseTeamMap,shareObject,parentField,objectData,null,teamGroupMap,strAccessLevelFieldName,strAccessLevel,strRowCause));
                }
                else{
                    shareRecords.add(createShareRecords(objectMappings[0],caseTeamMap,shareObject,parentField,objectData,teamUserMap,null,strAccessLevelFieldName,strAccessLevel,strRowCause));
                }
            }
                    
        if(!shareRecords.isEmpty()) {
            for(List<SObject> shareObjects : shareRecords){
                for(SObject oObject : shareObjects){
                    shareRecordToUpdate.add(oObject);
                }
            }
            list<Database.SaveResult> sr = Database.Insert(shareRecordToUpdate,false);
             system.debug('insert result'+JSON.serializePretty(sr));
        }
        }
    }

     public static List<SObject> createShareRecords(Object_Sharing__mdt objectMetadata,map<Id,id> caseTeam,String strShareObjectName, String strParentField, List<sObject> sObjectData,map<id,list<id>> userMap, Map<id,id> teamGroupIds,String strAccessLevelFieldName, String strAccessLevel, String strRowCause) {
        SObjectType objectType = Schema.getGlobalDescribe().get(strShareObjectName);
        list<SObject> lstObjects = new list<SObject>();
        
        for(sObject objectId : sObjectData) {
            if(userMap?.keySet()?.size() >0){
                Id teamId = caseTeam.get(objectId.Id);
                for(Id userOrGroupId : userMap.get(teamId)) {
                SObject shareRecord = objectType.newsObject();
                shareRecord.put(strParentField, objectId.id);
                shareRecord.put(strAccessLevelFieldName, strAccessLevel);
                shareRecord.put('UserOrGroupId', userOrGroupId);
                if(!string.isBlank(strRowCause)){
                    shareRecord.put('RowCause', strRowCause);
                }else{
                    shareRecord.put('RowCause', objectMetadata.Sharing_Reason__c);
                }
                lstObjects.add(shareRecord);
                }
            }else{
                SObject shareRecord = objectType.newsObject();
                shareRecord.put(strParentField, objectId.id);
                shareRecord.put(strAccessLevelFieldName, strAccessLevel);
                shareRecord.put('UserOrGroupId',teamGroupIds.get(caseTeam.get(objectId.Id)));
                if(!string.isBlank(strRowCause)){
                    shareRecord.put('RowCause', strRowCause);
                }else{
                    shareRecord.put('RowCause', objectMetadata.Sharing_Reason__c);
                }
                lstObjects.add(shareRecord);
            }
        }
        
        return lstObjects;
    }
    
    
    // public static void deleteOldShareRecords(set<id> sObjectIds ,string rowcause){
    //     List<SObject> sharesToDelete = new List<SObject>();


    //     if(string.isEmpty(rowcause)){
    //         sharesToDelete = [SELECT Id FROM CaseShare WHERE CaseId IN :sObjectIds AND RowCause = 'Manual'];
    //     }
    //     else{
    //         sharesToDelete = [SELECT Id FROM CaseShare WHERE CaseId IN :sObjectIds AND RowCause =:rowcause];
    //     }

    //     if(!sharesToDelete.isEmpty()){
    //         Database.Delete(sharesToDelete, false);
    //     }
    // }
}