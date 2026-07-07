function claude-sub --description 'Launch Claude Code on the subscription account (not Bedrock)'
    env -u CLAUDE_CODE_USE_BEDROCK -u AWS_PROFILE -u AWS_REGION \
        -u AWS_CONFIG_FILE -u AWS_ENDPOINT_URL -u AWS_DEFAULT_REGION \
        claude --model claude-opus-4-8 $argv
end
