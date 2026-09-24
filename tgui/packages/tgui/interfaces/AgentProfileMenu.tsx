import {
  Box,
  Button,
  Dropdown,
  Input,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Table,
  TextArea,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Profile = {
  name: string;
  label: string;
  persona: string;
  background: string;
  voice: string;
  limits: string;
  permitted_actions: string[];
  aliases: string[];
  memory_turns: number | null;
};

type BuiltIn = Omit<Profile, 'name'> & { type: string };

type Target = {
  ref: string;
  name: string;
  agent: BooleanLike;
  humanoid: BooleanLike;
  player: BooleanLike;
};

type Data = {
  profiles: Profile[];
  selected: string | null;
  targets: Target[];
  subsystemEnabled: BooleanLike;
  registered: number;
  vocabulary: string[];
  builtins: BuiltIn[];
  labelMax: number;
  textMax: number;
  aliasMax: number;
  memoryMax: number;
  memoryStart: number;
};

/** The long text fields, in the order they read as a character brief. */
const TEXT_FIELDS: { key: keyof Profile; label: string; hint: string }[] = [
  { key: 'persona', label: 'Persona', hint: 'Who they are. Written in second person.' },
  { key: 'background', label: 'Background', hint: 'What they know. Character knowledge, not server truth.' },
  { key: 'voice', label: 'Voice', hint: 'How they speak.' },
  { key: 'limits', label: 'Limits', hint: 'What they cannot do. Also enforced in DM.' },
];

export function AgentProfileMenu(props) {
  const { act, data } = useBackend<Data>();
  const {
    profiles = [],
    selected,
    targets = [],
    subsystemEnabled,
    registered,
    vocabulary = [],
    builtins = [],
    labelMax,
    textMax,
    aliasMax,
    memoryMax,
    memoryStart,
  } = data;

  const editing = profiles.find((profile) => profile.name === selected);
  const template = builtins.find((builtin) => builtin.type === selected);

  return (
    <Window title="Agent NPC Profiles" width={940} height={720}>
      <Window.Content scrollable>
        {!subsystemEnabled && (
          <NoticeBox danger>
            SSagent_npc is off or disabled. You can still write profiles, but a
            spawned or attached NPC will not bind and will just stand there.
          </NoticeBox>
        )}
        <Stack>
          <Stack.Item basis="240px">
            <ProfileList
              profiles={profiles}
              builtins={builtins}
              selected={selected}
            />
          </Stack.Item>
          <Stack.Item grow>
            {editing ? (
              <Editor
                profile={editing}
                vocabulary={vocabulary}
                labelMax={labelMax}
                textMax={textMax}
                aliasMax={aliasMax}
                memoryMax={memoryMax}
                memoryStart={memoryStart}
              />
            ) : (
              <ReadOnly template={template} />
            )}
          </Stack.Item>
        </Stack>
        <Targets targets={targets} registered={registered} />
      </Window.Content>
    </Window>
  );
}

function ProfileList(props: {
  profiles: Profile[];
  builtins: BuiltIn[];
  selected: string | null;
}) {
  const { act } = useBackend<Data>();
  const { profiles, builtins, selected } = props;

  return (
    <Section
      title="Profiles"
      buttons={
        <Button
          icon="plus"
          tooltip="New editable profile, copied from whatever is selected."
          onClick={() => act('create', { from: selected })}
        >
          New
        </Button>
      }
    >
      <Box bold mb={0.5}>
        Built in
      </Box>
      {builtins.map((builtin) => (
        <Button
          key={builtin.type}
          fluid
          selected={selected === builtin.type}
          icon="lock"
          onClick={() => act('select', { name: builtin.type })}
        >
          {builtin.label}
        </Button>
      ))}
      <Box bold mt={1} mb={0.5}>
        Yours
      </Box>
      {profiles.length === 0 && (
        <Box color="label" italic>
          None yet. Select a built-in profile and press New to copy it.
        </Box>
      )}
      {profiles.map((profile) => (
        <Button
          key={profile.name}
          fluid
          selected={selected === profile.name}
          icon="user-pen"
          onClick={() => act('select', { name: profile.name })}
        >
          {profile.name}
        </Button>
      ))}
      <Box mt={1}>
        <Button icon="floppy-disk" onClick={() => act('save')}>
          Save to disk
        </Button>
        <Button
          icon="rotate-left"
          tooltip="Discard unsaved edits and reload the file."
          onClick={() => act('reload')}
        >
          Reload
        </Button>
      </Box>
    </Section>
  );
}

function ReadOnly(props: { template?: BuiltIn }) {
  const { act } = useBackend<Data>();
  const { template } = props;

  if (!template) {
    return (
      <Section title="Editor">
        <Box color="label">
          Select a profile on the left. Built-in profiles are read only; press
          New to make an editable copy.
        </Box>
      </Section>
    );
  }

  return (
    <Section
      title={`${template.label} (built in, read only)`}
      buttons={
        <Button
          icon="copy"
          onClick={() => act('create', { from: template.type })}
        >
          Copy to editable
        </Button>
      }
    >
      <Box mb={1}>Allowed: {template.permitted_actions.join(', ')}</Box>
      {(template.aliases || []).length > 0 && (
        <Box mb={1}>Also answers to: {template.aliases.join(', ')}</Box>
      )}
      <Box mb={1}>
        Memory:{' '}
        {template.memory_turns ?? 'sidecar default'}
      </Box>
      {TEXT_FIELDS.map((field) => (
        <Box key={field.key} mb={1}>
          <Box bold>{field.label}</Box>
          <Box color="label" preserveWhitespace>
            {template[field.key] as string}
          </Box>
        </Box>
      ))}
    </Section>
  );
}

function Editor(props: {
  profile: Profile;
  vocabulary: string[];
  labelMax: number;
  textMax: number;
  aliasMax: number;
  memoryMax: number;
  memoryStart: number;
}) {
  const { act } = useBackend<Data>();
  const {
    profile,
    vocabulary,
    labelMax,
    textMax,
    aliasMax,
    memoryMax,
    memoryStart,
  } = props;
  const memory = profile.memory_turns;

  return (
    <Section
      title={`Editing "${profile.name}"`}
      buttons={
        <Button.Confirm
          icon="trash"
          color="bad"
          onClick={() => act('delete', { name: profile.name })}
        >
          Delete
        </Button.Confirm>
      }
    >
      <Stack mb={1}>
        <Stack.Item basis="50%">
          <Box bold mb={0.5}>
            Name
          </Box>
          {/* Committed on blur, so a keystroke is not a server round trip. */}
          <Input
            fluid
            value={profile.name}
            maxLength={labelMax}
            onBlur={(value) => act('rename', { name: value })}
          />
        </Stack.Item>
        <Stack.Item basis="50%">
          <Box bold mb={0.5}>
            Label (sent to the model)
          </Box>
          <Input
            fluid
            value={profile.label}
            maxLength={labelMax}
            onBlur={(value) => act('set_field', { field: 'label', value })}
          />
        </Stack.Item>
      </Stack>

      <Box bold>Also answers to</Box>
      <Box color="label" fontSize="0.9em" mb={0.5}>
        Up to {aliasMax} other names, comma separated: a nickname, or a
        spelling players use, such as a Cyrillic one. Ignored while masked.
      </Box>
      <Input
        fluid
        mb={1}
        value={(profile.aliases || []).join(', ')}
        onBlur={(value) => act('set_aliases', { value })}
      />

      <Box bold>Memory</Box>
      <Box color="label" fontSize="0.9em" mb={0.5}>
        Exchanges this character remembers, 0 to {memoryMax}. Each one is resent
        on every request, so more memory costs more tokens per decision.
      </Box>
      <Box mb={1}>
        {memory === null || memory === undefined ? (
          <>
            <Box inline color="label">
              Sidecar default.
            </Box>{' '}
            <Button onClick={() => act('set_memory', { value: memoryStart })}>
              Set my own
            </Button>
          </>
        ) : (
          <>
            <NumberInput
              width="4em"
              value={memory}
              minValue={0}
              maxValue={memoryMax}
              step={1}
              onChange={(value: number) => act('set_memory', { value })}
            />{' '}
            <Button onClick={() => act('set_memory', { default: true })}>
              Use sidecar default
            </Button>
          </>
        )}
      </Box>

      <Box bold mb={0.5}>
        Permitted actions
      </Box>
      <Box mb={1}>
        {vocabulary.map((entry) => (
          <Button.Checkbox
            key={entry}
            checked={profile.permitted_actions.includes(entry)}
            disabled={entry === 'wait'}
            tooltip={
              entry === 'wait'
                ? 'Always allowed. Without it the character can never end a conversation.'
                : undefined
            }
            onClick={() => act('toggle_action', { action: entry })}
          >
            {entry}
          </Button.Checkbox>
        ))}
      </Box>

      {TEXT_FIELDS.map((field) => (
        <Box key={field.key} mb={1}>
          <Box bold>{field.label}</Box>
          <Box color="label" fontSize="0.9em" mb={0.5}>
            {field.hint}
          </Box>
          <TextArea
            height="5rem"
            value={profile[field.key] as string}
            maxLength={textMax}
            onBlur={(value) => act('set_field', { field: field.key, value })}
          />
        </Box>
      ))}
    </Section>
  );
}

function Targets(props: { targets: Target[]; registered: number }) {
  const { act, data } = useBackend<Data>();
  const { targets, registered } = props;
  const { selected } = data;

  return (
    <Section
      title="Spawn and attach"
      buttons={
        <Button
          icon="user-plus"
          disabled={!selected}
          tooltip={
            selected ? undefined : 'Select a profile first.'
          }
          onClick={() => act('spawn')}
        >
          Spawn here
        </Button>
      }
    >
      <Box color="label" mb={1}>
        {registered} NPC(s) registered. Mobs in view, nearest listed as found:
      </Box>
      {targets.length === 0 && <Box color="label">Nothing in view.</Box>}
      {targets.length > 0 && (
        <Table>
          <Table.Row header>
            <Table.Cell>Mob</Table.Cell>
            <Table.Cell collapsing>State</Table.Cell>
            <Table.Cell collapsing />
          </Table.Row>
          {targets.map((target) => (
            <Table.Row key={target.ref}>
              <Table.Cell>{target.name}</Table.Cell>
              <Table.Cell collapsing>
                {target.player ? (
                  <Box color="bad">player</Box>
                ) : target.agent ? (
                  <Box color="good">agent</Box>
                ) : target.humanoid ? (
                  <Box color="label">humanoid</Box>
                ) : (
                  // The controller's fallback is stand, resist and flee, and its
                  // actions are speech. On a non-humanoid that mostly does not fit.
                  <Box color="average">not humanoid</Box>
                )}
              </Table.Cell>
              <Table.Cell collapsing>
                {target.agent ? (
                  <Button
                    icon="link-slash"
                    onClick={() => act('detach', { ref: target.ref })}
                  >
                    Detach
                  </Button>
                ) : (
                  <Button
                    icon="link"
                    disabled={!selected || !!target.player}
                    tooltip={
                      target.player
                        ? 'A mob with a client is never driven by the agent.'
                        : selected
                          ? undefined
                          : 'Select a profile first.'
                    }
                    onClick={() => act('attach', { ref: target.ref })}
                  >
                    Attach
                  </Button>
                )}
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
}
