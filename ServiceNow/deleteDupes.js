/**
 * deleteDupes() - deletes duplicate records based on a criterion function you define,
 *                 returns number of records deleted. 
 *                 you shouldn't need this if you don't screw up your instance :P
 */
Object.size = function(obj) {
    var size = 0, key;
    for (key in obj) {
        if (obj.hasOwnProperty(key)) size++;
    }
    return size;
};

function getRecords(table, query) {
    var gr = new GlideRecord(table);
    gr.addQuery(query);
    gr.query();
    
   return gr;
}

function deleteDupes(gr, hasher) {
    // hasher is an appropriate function for uniqely storing an item
    var hash = new Object();
    var dupes = new Object();

    while (gr.next()) {
    var key = hasher(gr);
    if (key in hash) {
        // if item in the hash, add it to dupes list
        dupes[key] = gr.sys_id;
    } else {
        // else add item to hash
        hash[key] = gr.sys_id;
    }
    }
    return Object.size(dupes);
}

/** in this example deleting task_time_worked dupes, the hash key will be concatenation of:
 *
 *     task GUID
 *     time_in_seconds 
 *     truncated glide_date_time (without the seconds)
 * 
 * ...this could miss a few and could overmatch a few, but it's close enough.
 **/ 
var gr = getRecords('task_time_worked', 
            "sys_created_on<javascript:gs.dateGenerate('2013-10-30','04:00:00')"
                + "^sys_created_on>javascript:gs.dateGenerate('2013-09-27','21:00:00')"
                + "^task.sys_class_name=incident");
gs.print(gr.getRowCount() + ' records in initial query');

var d = deleteDupes(gr, function(r){
                            return r.task 
                            + ',' + r.time_in_seconds
                            + ',' + (r.sys_created_on).substring(0, 20);
                        });
gs.print(d + ' duplicate records deleted');

