#!/usr/bin/env bash

# implements resty
rest() {
    OPTIND=1
    local uri=${1:-"/"}
    local index=${2:-"${RACKINDEX}"}
    local port=${3:-"$ecs_port"}
    shift 3
    ECS_TOKEN=$(cat $(ecs-cookiefile ${index})) || return 1
    export ECS_TOKEN
    source $script_bin/resty -W https://"${rack_master[index]}":"${port}""${uri}" -k -m ${api_timeout} -H "Content-Type: application/json" \
    -H "X-EMC-REST-CLIENT: TRUE" \
    -H "X-SDS-AUTH-TOKEN: $ECS_TOKEN" \
    -H "Accept: application/json,application/octet-stream,text/html,application/xhtml+xml,application/xml,image/webp"
    return $?
}

htraw() {
    source $script_bin/resty -W "${*}" -k -i -m ${api_timeout}
}

# SUNDAY SUNDAY SUNDAY cygwinisms vs. bashisms!
# cleans up encap from JSON vars for consumption by bash.
# note the \r in the filter. Yes, really. I know. I was there, man.
vc() {
    local input=${*}
    local output=''
    if [ -z "$input" ]; then
        while read -r input; do
            output+=${input//[$'\"\t\r\n ']}
        done
    else
        while read -r input; do
            output=${input//[$'\"\t\r\n ']}
        done <<< $input
    fi
    echo ${output}
}

#
# pretty printing lowercase versions for interactive usage
get() {
    GET $@ 2>&1 | jq -C .
}

post() {
    POST $@ 2>&1 | jq -C .
}

delete() {
    DELETE $@ 2>&1 | jq -C .
}

put() {
    PUT $@ 2>&1 | jq -C .
}

list_to_obj() {
    local input="$*"
    local blob=''
    blob+="{"
    if [ -z "$input" ]; then
        while read -d '%' -r key value; do
            blob+="\"$key\":\"$value\","
        done
    else
        while read -d '%' -r key value; do
            blob+="\"$key\":\"$value\","
        done <<< $input
    fi
    blob=${blob%,}
    blob+="}"
    echo "$blob"
}

list_to_arr() {
    local input="$*"
    local blob=''
    blob+="{"
    if [ -z "$input" ]; then
        while read -d '%' -r key value; do
            blob+="\"$key\":\"$value\","
        done
    else
        while read -d '%' -r key value; do
            blob+="\"$key\":\"$value\","
        done <<< $input
    fi
    blob=${blob%,}
    blob+="}"
    echo "$blob"
}

rest_error_map() {
(grep ^${1}$'\t' | cut -f 2) <<EOL
127	Exceeding assignment limit
1002	URI parameter is invalid
1003	Unsupported or missing media type
1004	Request parameter cannot be found
1005	Required parameter is missing or empty
1006	Request parameter is inactive and marked for deletion
1007	Method not supported
1008	Parameter was provided but invalid
1009	Bad headers
1010	Resource marked For deletion
1011	Unable to use provided VPool
1012	Unable to make requested change
1013	Bad request body
1014	Parameter value not within range
1015	Resource already exists
1016	Invalid zone specified
1017	Unable to register system
1018	Not registered
1019	Resource not found
1020	Resource is being referenced
1021	Unable to find a suitable placement to handle the request
1022	Already registered
1023	Version is not supported
1025	Unable to delete resource
1026	Insufficient permissions for user
1028	Unsupported role assignment
1029	Time bucket parameter invalid
1030	Virtual pool change would be disruptive
1031	Exceeding limit
1032	An error occurred during quota validation for provisioning
1033	Unknown RecoverPoint configuration specified
1034	An error occurred while finding a suitable placement to handle the request
1035	Attachment(s) size is more than maximum allowed
1036	Invalid volume type
1037	Invalid protection virtual pool configuration.
1038	Invalid file share name specified
1039	Invalid Network Configuration
1040	Invalid virtual pool
1041	There is no download in progress
1042	Operation not supported on ingested volumes
1042	Invalid maximum continuous copies
1043	The high availability for the continuous copies virtual pool is invalid
1044	Invalid continuous copies vpool
1045	Invalid action
1046	Virtual pool in use as continuous copies virtual pool
1047	API not been initialized
1048	Unable to find mirror virtual pool
1049	Parameter was not provided
2000	Unable to find entity in request URL
2001	URI parameter is inactive and marked for deletion
3000	This operation is forbidden for this resource using the specified credentials
3001	This operation is forbidden due to license check failure.
4000	Invalid credentials or authentication token provided to access to this resource
5001	An error occurred in the controller during a file operation
5002	An error occurred in the controller during a file storage device connection operation
6000	Unable to connect to the service. The service is unavailable, try again later
6001	Download initializing
7000	An error occurred in the API Service
7001	An error occurred when getting the Jaxb context
7002	An error occurred in the Audit Log Service
7003	An error occurred in the Metering service
7004	Event retrieval error
7005	An occurred during the Ingestion Request
7006	An error occurred during deletion of the RP volume
7007	An error occurred during RP volume creation
7008	Error occurred during dowloading image
8000	An error occurred in the database
8001	Unable to find the object with the given id
8003	Failed to write to database
8004	Failed to read from database
8005	Failed to delete from database
8006	Failed to query from database
8007	Invalid annotation
8500	Unable to connect to the database service
8501	Dummy failure for testing
9000	Unable to queue the job
9001	An error occurred in the coordinator
9002	Error occurred while decoding from coordinator
9003	Invalid repository information
9004	Not connectable endpoint
9500	Unable to queue the job
9501	The coordinator was unable to locate the service
10000	A security error has occured.
10001	An error occurred while encoding/decoding of tokens
10004	Required parameter is missing or empty
10005	An error occurred while verifying the service signature
10500	A service which is required to complete the security request is unavailable
10501	ViPR keystore operation is unavailable
11000	Unable to schedule job
11001	Unable to locate device controller
11002	Unable to scan job
11003	Unable to monitor job
12002	An error occurred while metering storage devices
12003	An error occurred while monitoring storage devices
12005	URI parameter is invalid
12006	Controller Entity is marked for deletion
12007	An error occurred when updating the EndPoints
12008	Attempt to use an unknown transport zone
12009	Unable to find the controller entity
12011	An error occurred in getting the Block Object's Native ID
14000	An error occurred in a workflow step
14002	The workflow step has been cancelled
15000	Unable to dispatch to a controller
30000	Cluster state is not stable
30001	Error occurred while releasing lock
30002	Object is null or empty
30003	Error occurred while writing
30004	Error occurred while reading
30005	Error occurred while creating object
30006	Error occurred while retrieving object
30007	Error occurred while setting object
30008	Error occurred while updating object
30009	Self test wait to complete
30010	Self test error occurred
30011	Error occurred while executing upload install
30012	Error occurred while waking up other nodes
30013	ConnectEMC service not configured
30014	Error occurred when initializing SSL content for remote repository
30015	No node available to execute operations
30016	Object is invalid
30018	Error occurred while releasing lock not by the lock owner
30020	Invalid software version
30021	Local repository error occurred
30022	Remote repository error occurred
30023	Error occurred while calling internal api
30024	Internal exception occurred
30025	Error occurred while calling coordinator client
30026	Service is busy
30027	Error occurred while powering off other nodes
30028	Failed to download a new image
30029	Error occurred while restarting service
30030	Failed connecting to controller
40000	Datastore creation failed
40001	Datastore deletion failed
40002	Project is invalid
40003	Project not found for namespace
40004	ObjectStore is invalid
40005	ObjectStore not found for namespace
40006	ObjectStore being used is not compatible with the request
40007	ObjectStore does not have associated datastore
40008	Bucket already exists
40009	Invalid bucket name
40010	Bucket Owner not valid
40011	Invalid object virtual pool type
40012	Dataservice Invalid Varray
40013	No Data Store
40014	System being initialized
40015	Obj Vpool Lists Not Mutually Exclusive
40016	Internal error while listing data nodes
50000	Cannot connect the remote vdc
50001	Internal error occurred during vdc management operations
50002	Cannot acquire global lock for vdc operations
50003	The federation has more than two different versions
50004	The federation is unstable
51001	Invalid vdc status occurred when connecting vdc
51002	Precheck of adding vdc failed
51003	Failed to generate the new vdc config info
51004	Sync new cert failed
51005	Generate cert chain failed
51006	Sync vdc configuration of connecting vdc failed
51007	Postcheck of connecting vdc failed
51008	Update vdc status failed in connecting vdc
52001	Precheck of removing vdc failed
52002	Sync vdc configuration of removing vdc failed
52003	Postcheck of removing vdc failed
52004	Invalid vdc status occurred when removing vdc
53001	Cannot update all the vdc
53002	Invalid vdc status occurred when updating vdc
53003	Precheck of updating vdc failed
54001	The current VDC is not in correct status to perform disconnecting operation
54002	The VDC to be disconnected is still reachable
54003	Some vdc is under disconnecting or connected failed status
54004	Failed to disconnect the VDC
55001	Failed to reconnect the VDC
55002	The VDC is not in correct status to finish reconnect
55003	Back end node repair failed when perform reconnect opertion
55004	There is at least one vdc is unreachable with operator;
20	[deprecated] Invalid credentials or authentication token provided to access to this resource
30	[deprecated] Bad Parameters Supplied
70	[deprecated] An error occurred in the API service
160	[deprecated] An error occurred in the controller
180	[deprecated] An error occurred in the storage controller
190	[deprecated] An error occurred in the object controller
200	[deprecated] Unable to find a suitable controller to handle the request
210	[deprecated] An error occurred executing a step in the controller workflow
240	[deprecated] An error occurred in the controller while executing a workflow step
250	[deprecated] Attempt to start a controller workflow that is already running
290	[deprecated] An error occurred while encoding/decoding of tokens
320	[deprecated] An IO error occurred, please check the ViPR logs for more information
EOL
}

