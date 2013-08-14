//Required Vars for Dataserver and llTeleportAgent Request
string simName;
vector simGlobalCoords;
vector landingPoint;
 
key owner;

string destname;// Destination as parsed from Stargate API
vector destpos; // Position as parsed from Stargate API
integer sensornum; // I don't remember what this is for but I'm going ot keep it in case it's used later.
 
integer COMM_STARGATE1 = -905000;
integer COMM_STARGATE2 = -805000;

list data;
string m1;
string m0;
integer tpchan = -314159;

integer COMM_CHANNEL;

integer encodeKey(string this_input) {
    integer i;
    integer max_i = llStringLength(this_input);
    integer this_total;
    string this_chr;
    integer first_num;
    integer last_num;
    
    for (i = 0; i < max_i; i++) {
        this_chr = llGetSubString(this_input, i, i);
        if (this_chr != "-") {
            last_num = (integer)("0x" + this_chr) + 1;
            if (!first_num) first_num = last_num;
            this_total = this_total + last_num;
        }
    }
    return (llAbs(this_total * first_num * last_num * (llRound(last_num / first_num) + 1)) + 42) * -1;
}

default {
    on_rez(integer start_param) {
        llResetScript();
    }
 
    state_entry() {
        owner = llGetOwner();
        COMM_CHANNEL = encodeKey(owner);
        llListen(COMM_CHANNEL, "", "", "");
        llListen(COMM_STARGATE1, "", NULL_KEY, "");
        llListen(COMM_STARGATE2, "", NULL_KEY, "");
 
        llRequestPermissions(owner, PERMISSION_TELEPORT); // We kinda need these in order to teleport your ass
    }
    
    listen(integer chan, string name, key id, string msg) {
        if (msg == "hello badge") llRegionSayTo(id, COMM_CHANNEL, "hello telepad");
        else if (chan == COMM_STARGATE1 || chan == COMM_STARGATE2) { // Listen for both AP and AMW gates 
            //llSay(0, msg);
            list message = llParseString2List(msg, ["|"], [""]);
            string m0 = llList2String(message, 0);
            string m1 = llList2String(message, 1);
            string m2 = llList2String(message, 2);
            string m3 = llList2String(message, 3);
            string m4 = llList2String(message, 4); 
            string m5 = llList2String(message, 5);   
     
            if (m0 == "dial lookup" && m1 == "successful") { // If lookup was successful and there's actually a sim to go to, 
                destname = m4; // Set the sim name variable
                destpos = (vector)m5; // Set the target coordinates
                simName = destname;
                landingPoint = destpos;
                llRequestSimulatorData(simName, DATA_SIM_POS); // Get the global coords
                //llSay(0, "Destination set");
            }
            if (m0 == "wormhole collision" && (key)m2 == llGetOwner()) { // Our owner just walked through the wormhole
                llTeleportAgentGlobalCoords(owner, simGlobalCoords, landingPoint, ZERO_VECTOR); // time to whoosh
                //llSay(0, "I tried to teleport you! i swear!"); 
            }
        } else {
            data = llParseString2List(msg, ["|"], [""]);
            m0 = llList2String(data, 0);
            m1 = llList2String(data, 1);
            if ((key)m0 == llGetOwner()) llTeleportAgent(llGetOwner(), "", (vector)m1, <1,1,1>);
        }
    }
    
    changed(integer change) { //attached?
        if (change & CHANGED_OWNER) llResetScript();
    }
 
    run_time_permissions(integer perm) {
        // if permission request has been denied (read ! as not)
        if (!(perm & PERMISSION_TELEPORT)) {
            llOwnerSay("I need permissions to teleport you!");
            llRequestPermissions(owner, PERMISSION_TELEPORT);
        }
    }
 
//  dataserver event only called if data is returned
//  or in other words, if you request data for a sim that does
//  not exist this event will NOT be called
 
    dataserver(key query_id, string data) {
        simGlobalCoords = (vector)data;
        // llOwnerSay("Sim global coords: " + (string)simGlobalCoords);
    }
}
