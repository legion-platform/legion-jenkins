*** Settings ***
Documentation       Check if jenkins components are secured
Resource            ../resources/keywords.robot
Variables           ../load_variables_from_profiles.py    ${PATH_TO_PROFILES_DIR}
Library             Collections
Library             legion_jenkins_test.robot.Utils

*** Test Cases ***
Checking Jenkins domain has been registered
    [Documentation]  Check that Jenkin DNS A record has been registered
    Check domain exists  jenkins.${HOST_BASE_DOMAIN}

Check if Jenkins domain has been secured
    [Template]    Check if component domain has been secured
    component=jenkins    enclave=${EMPTY}

Check if Jenkins domain does not auth with invalid creds
    [Template]    Secured component domain should not be accessible by invalid credentials
    component=jenkins    enclave=${EMPTY}

Check if Jenkins domain can auth with valid creds
    [Template]    Secured component domain should be accessible by valid credentials
    component=jenkins    enclave=${EMPTY}
