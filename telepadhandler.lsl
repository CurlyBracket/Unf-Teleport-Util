integer COMM_TELEPAD;
integer COMM_LOCAL;
integer COMM_BEAM;

float   TIME_INIT_TIMEOUT = FALSE;
float   TIME_CHECK_TIMEOUT = FALSE;
float   TIME_CHECK_NAME = FALSE;

float   TIME_INIT_TIMEOUT_INC = 2.5;
float   TIME_CHECK_TIMEOUT_INC = 0.5;
float   TIME_CHECK_NAME_INC = 1.0;

list    DEST_UUID;
list    DEST_NAME;
list    DEST_LABEL;

string  MY_OBJECT_NAME;  
string  MY_OBJECT_DESC;

string  MENU_PGUP = "-->";
string  MENU_PGDN = "<--";
string  MENU_BACK = "[BACK]";

key     MENU_TARGET;
string  MENU_MESSAGE;
integer MENU_PAGE = -1;

say(string m) {
    llSay(0, m);
}

integer rand(integer i) {
    return llFloor(llFrand((float)i));
}

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

integer addDestination(key id, string name) {
    integer index = llListFindList(DEST_UUID, [id]);
    integer output = -1;
    string label = llGetSubString(name, 0, 23);
    if (index == -1) {
        DEST_UUID += [id];
        DEST_NAME += [name];
        DEST_LABEL += [label];
        //say("Added " + name);
        output = llGetListLength(DEST_UUID) - 1;
    } else {
        DEST_LABEL = llListReplaceList(DEST_LABEL, [label], index, index);
        output = index;
    }
    return output;
}

integer deleteDestination(key id) {
    integer index = llListFindList(DEST_UUID, [id]);
    integer output = -1;
    if (index != -1) {
        string name = llList2String(DEST_NAME, index);
        DEST_UUID = llDeleteSubList(DEST_UUID, index, index);
        DEST_NAME = llDeleteSubList(DEST_NAME, index, index);
        DEST_LABEL = llDeleteSubList(DEST_LABEL, index, index);
        //say("Deleted " + name);
        output = index;
    }
    return output;
}

dumpDestinations() {
    integer i;
    integer i_max = llGetListLength(DEST_UUID);
    key id;
    for (i = 0; i < i_max; ++i) {
        id = llList2Key(DEST_UUID, i);
        say(llList2String(DEST_NAME, i) + " (" + (string)id + ") " + llList2String(llGetObjectDetails(id, [OBJECT_POS]), 0));
    }
}

menuPageCall(key target, string message, integer page) {
    MENU_TARGET = target;
    MENU_MESSAGE = message;
    MENU_PAGE = page;
    list buttons = getMenuButtons(page);
    if (llList2String(buttons, 0) != " ") menuPaged(target, message, buttons, COMM_LOCAL, page, (integer)((llGetListLength(DEST_UUID) - 1) / 9));
    else say("ERROR: No destinations set!");
}

list getMenuButtons(integer page) {
    integer page_start = page * 9;
    integer page_stop = page_start + 9;
    integer i;
    string name;
    list output;
    for (i = page_start; i < page_stop; ++i) {
        name = llList2String(DEST_LABEL, i);
        if (name != "") output += [name];
        else output += [" "];
    }
    return output;
}

menu(key target, string message, list buttons, integer channel) {
    // Rearrange the list of buttons so they appear in the correct order
    buttons = llList2List(buttons, 9, 11) + llList2List(buttons, 6, 8) + llList2List(buttons, 3, 5) + llList2List(buttons, 0, 2);
        
    // Output the menu
    llDialog(target, message, buttons, channel);
}

menuPaged(key target, string message, list buttons, integer channel, integer page, integer page_max) {
    // Determine which page buttons need to be placed
    string  menu_pgdn = " ";
    string  menu_pgup = " ";
    if (page) menu_pgdn = MENU_PGDN;
    if (page < page_max) menu_pgup = MENU_PGUP;
    menu(target, message, llList2List(buttons, 0, 8) + [menu_pgdn, MENU_BACK, menu_pgup], channel); 
}

// UPDATES
list    SENSED_AVATAR;
list    SENSED_AVATAR_NAME;
list    SENSED_AVATAR_COMM;
list    SENSED_AVATAR_COMM_H;
float   TIME_SENSE_TIMEOUT = FALSE;
key     SENSED_CHECK;

integer MENU_SENSED = FALSE;

integer INIT = FALSE;

key     SUPPRESS_NEXT;
vector  REZ_DEST = ZERO_VECTOR;

key     SENSE_MASTER = NULL_KEY;
list    SUPPRESSED_AVATAR;

sense() {
    TIME_SENSE_TIMEOUT = llGetTime() + 1;
    SENSE_MASTER = llList2Key(SENSED_AVATAR, 0);
    if (SENSE_MASTER == "") SENSE_MASTER = NULL_KEY;
    vector size = llGetScale();
    if (size.x != size.y) llSetScale(<size.x, size.x, size.z>);
    llSensor("", "", AGENT, size.x, PI);
}

integer addSensed(key id, string name) {
    integer index = llListFindList(SENSED_AVATAR, [id]);
    integer output = -1;
    if (index == -1) {
        integer comm = encodeKey(id);
        SENSED_AVATAR += [id];
        SENSED_AVATAR_NAME += [name];
        SENSED_AVATAR_COMM += [comm];
        SENSED_AVATAR_COMM_H += [llListen(comm, "", "", "")];
        //say("Added " + name);
        output = llGetListLength(SENSED_AVATAR) - 1;
    }
    return output;
}

integer deleteSensed(key id) {
    integer index = llListFindList(SENSED_AVATAR, [id]);
    integer output = FALSE;
    if (index != -1) {
        string name = llList2String(SENSED_AVATAR_NAME, index);
        llListenRemove(llList2Integer(SENSED_AVATAR_COMM_H, index));
        SENSED_AVATAR = llDeleteSubList(SENSED_AVATAR, index, index);
        SENSED_AVATAR_NAME = llDeleteSubList(SENSED_AVATAR_NAME, index, index);
        SENSED_AVATAR_COMM = llDeleteSubList(SENSED_AVATAR_COMM, index, index);
        SENSED_AVATAR_COMM_H = llDeleteSubList(SENSED_AVATAR_COMM_H, index, index);
        //say("Deleted " + name);
        output = TRUE;
    }
    return output;
}

closeAllListeners() {
    if (SENSED_AVATAR != []) {
        integer i;
        integer i_max = llGetListLength(SENSED_AVATAR_COMM_H);
        for (i = 0; i < i_max; ++i) {
            //say("Goodbye " + llList2String(SENSED_AVATAR_NAME, i));
            llListenRemove(llList2Integer(SENSED_AVATAR_COMM_H, i));
        }
        SENSED_AVATAR = SENSED_AVATAR_NAME = SENSED_AVATAR_COMM = SENSED_AVATAR_COMM_H = [];
        //say("Wiped memory");
    }
}

integer addSuppress(key id) {
    integer index = llListFindList(SUPPRESSED_AVATAR, [id]);
    integer output = -1;
    if (index == -1) {
        integer comm = encodeKey(id);
        SUPPRESSED_AVATAR += [id];
        //say("Added " + name);
        output = llGetListLength(SUPPRESSED_AVATAR) - 1;
    }
    return output;
}

integer deleteSuppress(key id) {
    integer index = llListFindList(SUPPRESSED_AVATAR, [id]);
    integer output = FALSE;
    if (index != -1) {
        SUPPRESSED_AVATAR = llDeleteSubList(SUPPRESSED_AVATAR, index, index);
        //say("Deleted " + name);
        output = TRUE;
    }
    return output;
}

default {
    on_rez(integer blek) {
        llResetScript();
    }
    
    state_entry() {
        MY_OBJECT_NAME = llGetObjectName();
        MY_OBJECT_DESC = llGetObjectDesc();
        COMM_TELEPAD = encodeKey(llGetCreator()) + 42;
        COMM_LOCAL = COMM_TELEPAD - encodeKey(llGetKey()) - rand(999);
        COMM_BEAM = COMM_TELEPAD + 99;
        llListen(COMM_TELEPAD, "", "", "");
        llListen(COMM_LOCAL, "", "", "");
        llRegionSay(COMM_TELEPAD, "init");
        TIME_INIT_TIMEOUT = llGetTime() + TIME_INIT_TIMEOUT_INC;
        llSetTimerEvent(0.1);
    }
    
    listen(integer channel, string name, key id, string message) {
        if (channel == COMM_TELEPAD) {
            if (message == "init") {
                llRegionSayTo(id, COMM_TELEPAD, "init_reply");
                addDestination(id, llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0));
            } else if (message == "init_reply") {
                addDestination(id, llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0));
                TIME_INIT_TIMEOUT = llGetTime() + TIME_INIT_TIMEOUT_INC;
            } else if (message == "update") {
                //say("updating " + (string)id + "...");
                addDestination(id, llList2String(llGetObjectDetails(id, [OBJECT_DESC]), 0));
            }
            else if (llSubStringIndex(message, "suppress_next|") == 0) addSuppress(llList2String(llParseString2List(message, ["|"], []), 1));
        } else if (channel == COMM_LOCAL) {
            if (message == MENU_PGUP) menuPageCall(MENU_TARGET, MENU_MESSAGE, MENU_PAGE + 1);
            else if (message == MENU_PGDN) menuPageCall(MENU_TARGET, MENU_MESSAGE, MENU_PAGE - 1);
            else if (message == MENU_BACK) say("back!");
            else if (message != " ") {
                integer index = llListFindList(DEST_LABEL, [message]);
                if (index != -1) {
                    //say(llList2String(DEST_NAME, index));
                    key id = llList2String(DEST_UUID, index);
                    list box;
                    vector size;
                    vector pos;
                    integer target_channel;
                    integer i;
                    integer i_max = llGetListLength(SENSED_AVATAR);
                    key avatar;
                    vector my_pos = llGetPos();;
                    vector avatar_pos;
                    vector offset;
                    for (i = 0; i < i_max; ++i) {
                        avatar = llList2String(SENSED_AVATAR, i);
                        avatar_pos = llList2Vector(llGetObjectDetails(avatar, [OBJECT_POS]), 0);
                        offset = avatar_pos - my_pos;
                        box = llGetBoundingBox(avatar);
                        size = llList2Vector(box, 1) - llList2Vector(box, 0);
                        pos = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0) + offset;
                        target_channel = llList2Integer(SENSED_AVATAR_COMM, i);
                        llRegionSayTo(id, COMM_TELEPAD, "suppress_next|" + (string)avatar);
                        if (target_channel && MENU_SENSED) {
                            llWhisper(target_channel, (string)avatar + "|" + (string)pos);
                        } else {
                            REZ_DEST = pos;
                            llRezObject("beam", llGetPos() + offset, ZERO_VECTOR, ZERO_ROTATION, COMM_BEAM);
                        }
                    }
                    MENU_SENSED = FALSE;
                }
            }
        } else if (llListFindList(SENSED_AVATAR_COMM, [channel]) != -1) {
            key owner = llGetOwnerKey(id);
            if (message == "hello telepad" && owner == SENSED_CHECK) {
                MENU_SENSED = TRUE;
                //say(name + " says " + message);
                if (llListFindList(SUPPRESSED_AVATAR, [owner]) != -1) deleteSuppress(owner);
                else if (owner == SENSE_MASTER) menuPageCall(SENSED_CHECK, "Select a destination...", 0);
            }
        }
    }

    timer() {
        float time = llGetTime();

        if (TIME_INIT_TIMEOUT != FALSE && time >= TIME_INIT_TIMEOUT) {
            TIME_INIT_TIMEOUT = FALSE;
            TIME_CHECK_TIMEOUT = llGetTime() + TIME_CHECK_TIMEOUT_INC;
            TIME_CHECK_NAME = llGetTime() + TIME_CHECK_NAME_INC;
            //dumpDestinations();
            INIT = TRUE;
            sense();
        }
        
        if (TIME_CHECK_TIMEOUT != FALSE && time >= TIME_CHECK_TIMEOUT) {
            TIME_CHECK_TIMEOUT = llGetTime() + TIME_CHECK_TIMEOUT_INC;
            integer i;
            integer i_max = llGetListLength(DEST_UUID);
            string name;
            key id;
            for (i = 0; i < i_max; ++i) {
                id = llList2Key(DEST_UUID, i);
                name = llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0);
                if (name != MY_OBJECT_NAME) deleteDestination(id);
            }            
        }

        if (TIME_SENSE_TIMEOUT != FALSE && time >= TIME_SENSE_TIMEOUT) {
            closeAllListeners();
            TIME_SENSE_TIMEOUT = FALSE;
            sense();
        }

        if (TIME_CHECK_NAME != FALSE && time >= TIME_CHECK_NAME) {
            string desc = llGetObjectDesc();
            if (desc != MY_OBJECT_DESC) {
                MY_OBJECT_DESC = desc;
                //say("sending update");
                llRegionSay(COMM_TELEPAD, "update");
            }
            TIME_CHECK_NAME = llGetTime() + TIME_CHECK_NAME_INC;
        }
    }
    
    touch_start(integer n) {
        //dumpDestinations();
        if (!INIT) say("Please wait, building menu...");
        else {
            integer i;
            for (i = 0; i < n; ++i) menuPageCall(llDetectedKey(i), "Select a destination...", 0);
        }
    }

    sensor(integer sensed) {
        integer i;
        list agents;
        string name;
        key id;
        integer index;
        for (i = 0; i < sensed; ++i) {
            name = llDetectedName(i);
            id = llDetectedKey(i);
            index = addSensed(id, name);
            if (index != -1) {
                SENSED_CHECK = id;
                //say("Hello " + name);
                llWhisper(llList2Integer(SENSED_AVATAR_COMM, index), "hello badge");
            }
            agents += [id];
        }
        
        // Clear out old avatar data
        if (agents != []) {
            integer i_max = llGetListLength(SENSED_AVATAR);
            list delete;
            for (i = 0; i < i_max; ++i) {
                id = llList2Key(SENSED_AVATAR, i);
                if (llListFindList(agents, [id]) == -1) delete += [id];
            }
            
            i_max = llGetListLength(delete);
            for (i = 0; i < i_max; ++i) {
                //say("Goodbye " + llKey2Name(llList2String(delete, i)));
                deleteSensed(llList2Key(delete, i));
            }
        } else {
            closeAllListeners();
        }
        
        sense();
    }
    
    object_rez(key id) {
        if (REZ_DEST != ZERO_VECTOR) {
            llWhisper(COMM_BEAM, (string)REZ_DEST + "|" + (string)llGetColor(0));
            REZ_DEST = ZERO_VECTOR;
        }
    }
}
