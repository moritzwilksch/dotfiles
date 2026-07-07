function claude-sub --description 'Launch Claude Code on the subscription account (not Bedrock)'
    # ~/.claude/settings.json sets the Bedrock env vars, which Claude Code re-applies
    # on startup regardless of the shell env — so `env -u` here is useless. Instead we
    # layer an override settings file (via --settings) that empties those vars for this
    # session only, forcing the Anthropic API (subscription). The base settings.json is
    # untouched, so a plain `claude` still uses Bedrock.
    claude --settings $HOME/.claude/settings.subscription.json \
        --model claude-opus-4-8 $argv
end
