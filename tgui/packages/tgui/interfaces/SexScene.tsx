import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Tabs,
  TextArea,
  Tooltip,
} from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Booleanish = boolean | number;

type ActionEntry = {
  key: string;
  name: string;
  active: Booleanish;
  can_perform: Booleanish;
  user_zones: number;
  target_zones: number;
};

type ZoneOption = { name: string; value: number };

type ControlsData = {
  speed: number;
  force: number;
  resist: number;
  manual_arousal: number;
  has_penis: Booleanish;
  do_until_finished: Booleanish;
  edging_other: Booleanish;
  lying_direction: string | null;
};

type ArousalData = {
  arousal_pct: number;
  orgasm_pct: number;
  pain_pct: number;
};

type BellyActionEntry = {
  key: string;
  name: string;
  selected: Booleanish;
  can_perform: Booleanish;
};

type BellyData = null | { enabled: Booleanish; actions: BellyActionEntry[] };

type CustomOption = { name: string; value: number | string | null };

type CustomSelectorEntry = {
  id: string;
  name: string;
  summary: string;
  selected: Booleanish;
};

type CustomEditorData = null | {
  is_saved: Booleanish;
  name: string;
  scope: number;
  user_part: number;
  target_part: number;
  filter_summary: string;
  require_same_tile: Booleanish;
  require_grab: Booleanish;
  requires_free_hands: Booleanish;
  gags_user: Booleanish;
  gags_target: Booleanish;
  do_time_seconds: number;
  stamina_cost: number;
  user_arousal: number;
  user_pain: number;
  user_orgasm: number;
  target_arousal: number;
  target_pain: number;
  target_orgasm: number;
  message_start: string | null;
  message_tick: string | null;
  message_finish: string | null;
  message_climax_active: string | null;
  message_climax_passive: string | null;
  active_climax_location: string | null;
  passive_climax_location: string | null;
  created_text: string | null;
  modified_text: string | null;
};

type CustomData = {
  templates: CustomSelectorEntry[];
  saved: CustomSelectorEntry[];
  scope_options: CustomOption[];
  part_options: CustomOption[];
  climax_options: CustomOption[];
  editor: CustomEditorData;
};

type ErpFlag = {
  name: string;
  bit: number;
  description: string;
  on: Booleanish;
};

type ErpPrefEntry = {
  type: string;
  name: string;
  description: string;
  kind: 'bool' | 'flags' | 'number' | 'choice';
  value?: unknown;
  flags?: ErpFlag[];
  min?: number;
  max?: number;
  choices?: string[];
};

type ErpCategory = { name: string; prefs: ErpPrefEntry[] };

type KinkEntry = {
  name: string;
  description: string;
  enabled: Booleanish;
  intensity: number;
  notes: string;
};

type KinkCategory = { name: string; kinks: KinkEntry[] };

type IntimacyData = {
  lock_reason: string | null;
  yours: ErpCategory[];
  theirs: ErpCategory[];
  their_kinks: KinkCategory[];
};

type NoteEntry = { title: string; content: string; meta: string };
type NotesData = { yours: NoteEntry[]; theirs: NoteEntry[] };

type ScenePatternEntry = {
  key: string;
  id: string;
  name: string;
  focus_name: string | null;
  is_focus: Booleanish;
};

type SceneParticipantEntry = {
  ref: string;
  name: string;
  is_self: Booleanish;
  selected: Booleanish;
  action_count: number;
  status_lines: string[];
};

type SceneConnectionEntry = {
  ref: string;
  name: string;
  actor_name: string;
  target_name: string;
  speed: number;
  force: number;
  can_stop: Booleanish;
};

type SceneClaimEntry = {
  action_name: string;
  host_name: string;
  resource_name: string;
  hard: Booleanish;
};

type Data = {
  target_name: string;
  is_self: Booleanish;
  scene_name: string;
  scene_participants: SceneParticipantEntry[];
  scene_connections: SceneConnectionEntry[];
  scene_claims: SceneClaimEntry[];
  status_lines: string[];
  arousal: ArousalData;
  controls: ControlsData;
  zone_options: ZoneOption[];
  actions: ActionEntry[];
  scene_patterns: ScenePatternEntry[];
  bellyriding: BellyData;
  custom: CustomData;
  intimacy: IntimacyData;
  notes: NotesData;
};

const asBool = (value: Booleanish | undefined) => value === true || value === 1;

const SPEED_LABELS = ['Slow', 'Steady', 'Quick', 'Unrelenting'];
const FORCE_LABELS = ['Gentle', 'Firm', 'Rough', 'Brutal'];
const RESIST_LABELS = ['None', 'Low', 'Medium', 'High'];
const AROUSAL_LABELS = ['Natural', 'Unaroused', 'Partial', 'Full'];
const INTENSITY_LABELS = [
  'Very Light',
  'Light',
  'Moderate',
  'Intense',
  'Very Intense',
];

// One-click level picker: selected level shows its name, others show numbers.
const LevelControl = (props: {
  label: string;
  value: number;
  labels: string[];
  onSet: (level: number) => void;
}) => {
  const { label, value, labels, onSet } = props;
  return (
    <Stack align="center">
      <Stack.Item>
        <Box color="label" fontSize="10px" bold>
          {label}
        </Box>
      </Stack.Item>
      {labels.map((name, idx) => {
        const level = idx + 1;
        return (
          <Stack.Item key={name}>
            <Button
              compact
              selected={value === level}
              tooltip={name}
              onClick={() => onSet(level)}
            >
              {value === level ? name : String(level)}
            </Button>
          </Stack.Item>
        );
      })}
    </Stack>
  );
};

const ZoneFilterPanel = (props: {
  title: string;
  options: ZoneOption[];
  value: number;
  onChange: (value: number) => void;
}) => (
  <Section title={props.title}>
    {props.options.map((option) => (
      <Button
        key={option.value}
        fluid
        compact
        mb={0.25}
        textAlign="center"
        selected={props.value === option.value}
        onClick={() => props.onChange(option.value)}
      >
        {option.name}
      </Button>
    ))}
  </Section>
);

const zoneMatches = (mask: number, filter: number) =>
  filter === 0 || (mask & filter) !== 0;

export const SexScene = () => {
  const { act, data } = useBackend<Data>();

  const [tab, setTab] = useState('interactions');
  const [userZone, setUserZone] = useState(0);
  const [targetZone, setTargetZone] = useState(0);
  const [search, setSearch] = useState('');
  const [notesTab, setNotesTab] = useState<'yours' | 'theirs'>('yours');
  const [noteFormOpen, setNoteFormOpen] = useState(false);
  const [noteTitle, setNoteTitle] = useState('');
  const [noteContent, setNoteContent] = useState('');
  const [editingNote, setEditingNote] = useState<string | null>(null);
  const [editContent, setEditContent] = useState('');
  const [connectionsOpen, setConnectionsOpen] = useState(false);
  const [claimsOpen, setClaimsOpen] = useState(false);

  const controls = data.controls || ({} as ControlsData);
  const arousal = data.arousal || ({} as ArousalData);
  const scenePatterns = data.scene_patterns ?? [];
  const hasBelly = !!data.bellyriding;
  const activeTab = tab === 'bellyriding' && !hasBelly ? 'interactions' : tab;

  const renderParticipantTooltip = (participant: SceneParticipantEntry) => (
    <Box>
      <Box bold>{participant.name}</Box>
      <Box color="label" mb={0.5}>
        {asBool(participant.is_self) ? 'You' : 'Scene participant'} ·{' '}
        {participant.action_count} active interaction
        {participant.action_count === 1 ? '' : 's'}
      </Box>
      {(participant.status_lines ?? []).map((line, index) => (
        <Box key={`${participant.ref}-${index}`}>...{line}</Box>
      ))}
    </Box>
  );

  const renderParticipantButton = (participant: SceneParticipantEntry) => (
    <Stack.Item key={participant.ref}>
      <Tooltip
        content={renderParticipantTooltip(participant)}
        position="bottom-start"
      >
        <Box>
          <Button
            fluid
            compact
            selected={asBool(participant.selected)}
            onClick={() => act('select_participant', { ref: participant.ref })}
          >
            <Stack align="center">
              <Stack.Item grow style={{ minWidth: 0 }}>
                <Box
                  bold
                  style={{
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {participant.name}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Box as="span" color="label" fontSize="9px">
                  {participant.action_count}
                </Box>
              </Stack.Item>
            </Stack>
          </Button>
        </Box>
      </Tooltip>
    </Stack.Item>
  );

  const renderHeader = () => (
    <Section>
      <Stack>
        <Stack.Item basis="18%" shrink={0} style={{ minWidth: 0 }}>
          <Box bold color="label" fontSize="10px" mb={0.25}>
            Participants
          </Box>
          <Stack vertical maxHeight="9rem" overflowY="auto">
            {(data.scene_participants ?? []).map(renderParticipantButton)}
          </Stack>
        </Stack.Item>
        <Stack.Item grow style={{ minWidth: 0 }}>
          <Box bold fontSize="13px">
            {asBool(data.is_self)
              ? 'Interacting with yourself…'
              : `Interacting with ${data.target_name}…`}
          </Box>
          <Box color="label" fontSize="9px">
            Scene: {data.scene_name || data.target_name}
          </Box>
          <Box color="label" fontSize="10px" mt={0.25}>
            {(data.status_lines ?? []).map((line) => (
              <Box key={line}>…{line}</Box>
            ))}
          </Box>
          {scenePatterns.length ? (
            <Box color="pink" fontSize="10px" mt={0.5}>
              <Box as="span" bold>
                Active scene:{' '}
              </Box>
              {scenePatterns.map((pattern, index) => (
                <Box as="span" key={pattern.key}>
                  {index ? ', ' : ''}
                  {pattern.name}
                  {asBool(pattern.is_focus)
                    ? ' (centered on you)'
                    : pattern.focus_name
                      ? ` (centered on ${pattern.focus_name})`
                      : ''}
                </Box>
              ))}
            </Box>
          ) : null}
        </Stack.Item>
        <Stack.Item basis="38%">
          <LabeledList>
            <LabeledList.Item label="Orgasm">
              <ProgressBar
                value={(arousal.orgasm_pct || 0) / 100}
                color="pink"
              />
            </LabeledList.Item>
            <LabeledList.Item label="Arousal">
              <ProgressBar
                value={(arousal.arousal_pct || 0) / 100}
                color="red"
              />
            </LabeledList.Item>
            <LabeledList.Item label="Pain">
              <ProgressBar value={(arousal.pain_pct || 0) / 100} color="grey" />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
    </Section>
  );

  const renderActionButton = (action: ActionEntry) => (
    <Stack.Item key={action.key} basis="49%" grow>
      <Stack>
        <Stack.Item grow>
          <Button
            fluid
            compact
            disabled={!asBool(action.can_perform) && !asBool(action.active)}
            selected={asBool(action.active)}
            tooltip={action.name}
            onClick={() =>
              act(asBool(action.active) ? 'stop' : 'action', {
                key: action.key,
              })
            }
          >
            {action.name}
          </Button>
        </Stack.Item>
        {asBool(action.active) ? (
          <Stack.Item>
            <Button
              compact
              icon="times"
              color="bad"
              tooltip="Stop action"
              onClick={() => act('stop', { key: action.key })}
            />
          </Stack.Item>
        ) : null}
      </Stack>
    </Stack.Item>
  );

  const renderQuickBar = () => (
    <Section>
      <Stack align="center" wrap>
        <Stack.Item>
          <LevelControl
            label="SPEED"
            value={controls.speed}
            labels={SPEED_LABELS}
            onSet={(level) => act('set_speed', { value: level })}
          />
        </Stack.Item>
        <Stack.Item>
          <LevelControl
            label="FORCE"
            value={controls.force}
            labels={FORCE_LABELS}
            onSet={(level) => act('set_force', { value: level })}
          />
        </Stack.Item>
        <Stack.Item>
          <LevelControl
            label="HOLD"
            value={controls.resist}
            labels={RESIST_LABELS}
            onSet={(level) => act('set_resist', { value: level })}
          />
        </Stack.Item>
        {asBool(controls.has_penis) ? (
          <Stack.Item>
            <LevelControl
              label="AROUSAL"
              value={controls.manual_arousal}
              labels={AROUSAL_LABELS}
              onSet={(level) => act('set_manual_arousal', { value: level })}
            />
          </Stack.Item>
        ) : null}
        <Stack.Item grow />
        <Stack.Item>
          <Button
            compact
            selected={asBool(controls.do_until_finished)}
            tooltip="Stop automatically after a climax?"
            onClick={() => act('toggle_finished')}
          >
            {asBool(controls.do_until_finished)
              ? "Until I'm Finished"
              : 'Until I Stop'}
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            compact
            selected={asBool(controls.edging_other)}
            tooltip="Try to hold your partner back from the edge"
            onClick={() => act('toggle_edging')}
          >
            Edge {asBool(controls.edging_other) ? 'On' : 'Off'}
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            compact
            disabled={!controls.lying_direction}
            tooltip={
              controls.lying_direction
                ? `Currently ${controls.lying_direction}`
                : 'Only while lying down'
            }
            onClick={() => act('swap_side')}
          >
            Swap Side
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );

  const renderInteractions = () => {
    const actions = data.actions ?? [];
    const activeActions = actions.filter((action) => asBool(action.active));
    const inactive = actions.filter((action) => !asBool(action.active));
    const available = inactive.filter(
      (action) =>
        zoneMatches(action.user_zones, userZone) &&
        zoneMatches(action.target_zones, targetZone) &&
        (!search || action.name.toLowerCase().includes(search.toLowerCase())),
    );
    const connections = data.scene_connections ?? [];
    const claims = data.scene_claims ?? [];
    return (
      <Stack fill vertical>
        <Stack.Item grow>
          <Stack fill>
            <Stack.Item basis="110px" shrink={0}>
              <ZoneFilterPanel
                title="You use"
                options={data.zone_options ?? []}
                value={userZone}
                onChange={setUserZone}
              />
            </Stack.Item>
            <Stack.Item grow>
              <Section fill scrollable>
                <Stack align="start" mb={0.75}>
                  <Stack.Item grow basis={0} style={{ minWidth: 0 }}>
                    <Section
                      fitted
                      title={`Scene Connections (${connections.length})`}
                      buttons={
                        <Button
                          compact
                          icon={connectionsOpen ? 'chevron-up' : 'chevron-down'}
                          tooltip={
                            connectionsOpen
                              ? 'Collapse scene connections'
                              : 'Expand scene connections'
                          }
                          onClick={() => setConnectionsOpen(!connectionsOpen)}
                        />
                      }
                    >
                      {connectionsOpen ? (
                        <Stack vertical maxHeight="8rem" overflowY="auto">
                          {connections.length ? (
                            connections.map((connection) => (
                              <Stack.Item key={connection.ref}>
                                <Stack align="center">
                                  <Stack.Item grow style={{ minWidth: 0 }}>
                                    <Box fontSize="10px">
                                      <Box as="span" bold>
                                        {connection.actor_name}
                                      </Box>{' '}
                                      → {connection.target_name}:{' '}
                                      {connection.name}
                                    </Box>
                                  </Stack.Item>
                                  <Stack.Item>
                                    <Box color="label" fontSize="9px">
                                      S{connection.speed} / F{connection.force}
                                    </Box>
                                  </Stack.Item>
                                  {asBool(connection.can_stop) ? (
                                    <Stack.Item>
                                      <Button
                                        compact
                                        icon="times"
                                        color="bad"
                                        tooltip="Stop this connection"
                                        onClick={() =>
                                          act('stop_scene_action', {
                                            ref: connection.ref,
                                          })
                                        }
                                      />
                                    </Stack.Item>
                                  ) : null}
                                </Stack>
                              </Stack.Item>
                            ))
                          ) : (
                            <Stack.Item>
                              <Box color="label" fontSize="10px" italic>
                                No active scene connections.
                              </Box>
                            </Stack.Item>
                          )}
                        </Stack>
                      ) : null}
                    </Section>
                  </Stack.Item>
                  <Stack.Item grow basis={0} style={{ minWidth: 0 }}>
                    <Section
                      fitted
                      title={`Claimed Resources (${claims.length})`}
                      buttons={
                        <Button
                          compact
                          icon={claimsOpen ? 'chevron-up' : 'chevron-down'}
                          tooltip={
                            claimsOpen
                              ? 'Collapse claimed resources'
                              : 'Expand claimed resources'
                          }
                          onClick={() => setClaimsOpen(!claimsOpen)}
                        />
                      }
                    >
                      {claimsOpen ? (
                        <Stack vertical maxHeight="8rem" overflowY="auto">
                          {claims.length ? (
                            claims.map((claim, index) => (
                              <Stack.Item
                                key={`${claim.host_name}-${claim.resource_name}-${index}`}
                              >
                                <Box
                                  color={asBool(claim.hard) ? 'bad' : 'average'}
                                  fontSize="10px"
                                >
                                  {claim.host_name}: {claim.resource_name} —{' '}
                                  {claim.action_name}
                                  {asBool(claim.hard)
                                    ? ' (exclusive)'
                                    : ' (shared)'}
                                </Box>
                              </Stack.Item>
                            ))
                          ) : (
                            <Stack.Item>
                              <Box color="label" fontSize="10px" italic>
                                No resources are currently claimed.
                              </Box>
                            </Stack.Item>
                          )}
                        </Stack>
                      ) : null}
                    </Section>
                  </Stack.Item>
                </Stack>
                <Input
                  fluid
                  expensive
                  placeholder="Search for an interaction…"
                  value={search}
                  onChange={setSearch}
                />
                <Box color="label" fontSize="10px" my={0.5}>
                  Showing {available.length} of {inactive.length} available
                  interactions for the current filters.
                </Box>
                {activeActions.length ? (
                  <Section title="Active" fitted mb={1}>
                    <Stack wrap>{activeActions.map(renderActionButton)}</Stack>
                  </Section>
                ) : null}
                {available.length ? (
                  <Stack wrap>{available.map(renderActionButton)}</Stack>
                ) : (
                  <Box color="label" textAlign="center" p={2} italic>
                    No interactions match these filters.
                  </Box>
                )}
              </Section>
            </Stack.Item>
            <Stack.Item basis="110px" shrink={0}>
              <ZoneFilterPanel
                title={
                  asBool(data.is_self)
                    ? 'On yourself'
                    : `On ${data.target_name}`
                }
                options={data.zone_options ?? []}
                value={targetZone}
                onChange={setTargetZone}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item>{renderQuickBar()}</Stack.Item>
      </Stack>
    );
  };

  const renderBellyriding = () => {
    const belly = data.bellyriding;
    if (!belly) {
      return null;
    }
    return (
      <Section fill scrollable>
        <Section title="Harness Controls" fitted mb={1}>
          <Button
            fluid
            mb={0.5}
            selected={asBool(belly.enabled)}
            onClick={() => act('bellyriding_toggle')}
          >
            {asBool(belly.enabled)
              ? 'Disable Bellyriding Interactions'
              : 'Enable Bellyriding Interactions'}
          </Button>
          <Button fluid onClick={() => act('bellyriding_release')}>
            Release From Harness
          </Button>
        </Section>
        <Section title="Harness Actions" fitted>
          {belly.actions.map((action) => (
            <Stack key={action.key} mb={0.5}>
              <Stack.Item grow>
                <Button
                  fluid
                  disabled={!asBool(action.can_perform)}
                  selected={asBool(action.selected)}
                  onClick={() => act('bellyriding_action', { key: action.key })}
                >
                  {action.name}
                </Button>
              </Stack.Item>
              {asBool(action.selected) ? (
                <Stack.Item>
                  <Button
                    icon="times"
                    color="bad"
                    tooltip="Return to automatic bellyriding"
                    onClick={() => act('bellyriding_clear')}
                  />
                </Stack.Item>
              ) : null}
            </Stack>
          ))}
        </Section>
      </Section>
    );
  };

  const customField = (field: string, value: unknown) =>
    act('custom_field', { field, value });

  const renderCustomToggle = (label: string, field: string, on: Booleanish) => (
    <LabeledList.Item label={label}>
      <Button
        compact
        selected={asBool(on)}
        color={asBool(on) ? 'good' : 'bad'}
        onClick={() => customField(field, 1)}
      >
        {asBool(on) ? 'Yes' : 'No'}
      </Button>
    </LabeledList.Item>
  );

  const renderCustomNumber = (
    label: string,
    field: string,
    value: number,
    min: number,
    max: number,
  ) => (
    <LabeledList.Item label={label}>
      <NumberInput
        value={value}
        minValue={min}
        maxValue={max}
        step={0.1}
        width="55px"
        onChange={(next) => customField(field, next)}
      />
    </LabeledList.Item>
  );

  const renderCustomDropdown = (
    label: string,
    field: string,
    value: number | string | null,
    options: CustomOption[],
  ) => {
    // Dropdown values must be string|number; '' stands in for null ("Default")
    // and the backend sanitizer maps any non-enum value back to null.
    const ddOptions = (options ?? []).map((option) => ({
      displayText: option.name,
      value: option.value ?? '',
    }));
    const selected =
      ddOptions.find((option) => option.value === (value ?? '')) ?? null;
    return (
      <LabeledList.Item label={label}>
        <Dropdown
          width="140px"
          options={ddOptions}
          selected={selected}
          onSelected={(next) => customField(field, next === '' ? null : next)}
        />
      </LabeledList.Item>
    );
  };

  const renderCustomText = (
    label: string,
    field: string,
    value: string | null,
  ) => (
    <LabeledList.Item label={label}>
      <TextArea
        value={value || ''}
        height="38px"
        placeholder="Leave blank for a fallback line."
        onBlur={(next) => customField(field, next)}
      />
    </LabeledList.Item>
  );

  const renderCustomEditor = () => {
    const custom = data.custom;
    const editor = custom.editor;
    if (!editor) {
      return (
        <Box color="label" textAlign="center" p={3} italic>
          Pick a template on the left or load one of your saved custom actions.
        </Box>
      );
    }
    return (
      <>
        <Stack align="center" mb={1}>
          <Stack.Item grow>
            <Box bold>
              {asBool(editor.is_saved)
                ? 'Editing Saved Action'
                : 'Editing Draft'}
              : {editor.name}
            </Box>
            {editor.created_text ? (
              <Box color="label" fontSize="10px">
                Saved: {editor.created_text} | Updated:{' '}
                {editor.modified_text || editor.created_text}
              </Box>
            ) : null}
          </Stack.Item>
          <Stack.Item>
            <Button icon="save" color="good" onClick={() => act('custom_save')}>
              {asBool(editor.is_saved) ? 'Save Changes' : 'Create Action'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button icon="undo" onClick={() => act('custom_reset')}>
              Reset
            </Button>
          </Stack.Item>
          {asBool(editor.is_saved) ? (
            <Stack.Item>
              <Button.Confirm
                icon="trash"
                color="bad"
                confirmContent="Delete?"
                onClick={() =>
                  act('custom_delete', {
                    id: custom.saved.find((entry) => asBool(entry.selected))
                      ?.id,
                  })
                }
              >
                Delete
              </Button.Confirm>
            </Stack.Item>
          ) : null}
        </Stack>
        <Box color="label" fontSize="10px" mb={1}>
          Message tokens: {'{name}'}, {'{user}'}, {'{target}'}, {'{user_their}'}
          , {'{target_their}'}, {'{user_them}'}, {'{target_them}'}, {'{force}'},{' '}
          {'{speed}'}, {'{user_part}'}, {'{target_part}'}.
        </Box>
        <Section title="Basics" fitted mb={1}>
          <LabeledList>
            <LabeledList.Item label="Name">
              <Input
                fluid
                value={editor.name}
                onBlur={(next) => customField('name', next)}
                onEnter={(next) => customField('name', next)}
              />
            </LabeledList.Item>
            {renderCustomDropdown(
              'Scope',
              'scope',
              editor.scope,
              custom.scope_options,
            )}
            {renderCustomDropdown(
              'Acting Part',
              'user_part',
              editor.user_part,
              custom.part_options,
            )}
            {renderCustomDropdown(
              'Receiving Part',
              'target_part',
              editor.target_part,
              custom.part_options,
            )}
            <LabeledList.Item label="Interaction Filters">
              <Box color="label">{editor.filter_summary}</Box>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Rules" fitted mb={1}>
          <LabeledList>
            {renderCustomToggle(
              'Require Same Tile',
              'require_same_tile',
              editor.require_same_tile,
            )}
            {renderCustomToggle(
              'Require Grab',
              'require_grab',
              editor.require_grab,
            )}
            {renderCustomToggle(
              'Requires Free Hands',
              'requires_free_hands',
              editor.requires_free_hands,
            )}
            {renderCustomToggle(
              'Gag Acting Side',
              'gags_user',
              editor.gags_user,
            )}
            {renderCustomToggle(
              'Gag Receiving Side',
              'gags_target',
              editor.gags_target,
            )}
            {renderCustomNumber(
              'Cycle Time (s)',
              'do_time_seconds',
              editor.do_time_seconds,
              0.5,
              10,
            )}
            {renderCustomNumber(
              'Stamina Cost',
              'stamina_cost',
              editor.stamina_cost,
              0,
              10,
            )}
          </LabeledList>
        </Section>
        <Section title="Effects Per Cycle" fitted mb={1}>
          <LabeledList>
            {renderCustomNumber(
              'Actor Arousal',
              'user_arousal',
              editor.user_arousal,
              0,
              10,
            )}
            {renderCustomNumber(
              'Actor Pain',
              'user_pain',
              editor.user_pain,
              0,
              10,
            )}
            {renderCustomNumber(
              'Actor Orgasm Progress',
              'user_orgasm',
              editor.user_orgasm,
              0,
              10,
            )}
            {renderCustomNumber(
              'Receiver Arousal',
              'target_arousal',
              editor.target_arousal,
              0,
              10,
            )}
            {renderCustomNumber(
              'Receiver Pain',
              'target_pain',
              editor.target_pain,
              0,
              10,
            )}
            {renderCustomNumber(
              'Receiver Orgasm Progress',
              'target_orgasm',
              editor.target_orgasm,
              0,
              10,
            )}
          </LabeledList>
        </Section>
        <Section title="Messages" fitted mb={1}>
          <LabeledList>
            {renderCustomText(
              'Start Message',
              'message_start',
              editor.message_start,
            )}
            {renderCustomText(
              'Cycle Message',
              'message_tick',
              editor.message_tick,
            )}
            {renderCustomText(
              'Finish Message',
              'message_finish',
              editor.message_finish,
            )}
          </LabeledList>
        </Section>
        <Section title="Climax Handling" fitted>
          <LabeledList>
            {renderCustomText(
              'Actor Climax Message',
              'message_climax_active',
              editor.message_climax_active,
            )}
            {renderCustomDropdown(
              'Actor Climax Result',
              'active_climax_location',
              editor.active_climax_location,
              custom.climax_options,
            )}
            {renderCustomText(
              'Receiver Climax Message',
              'message_climax_passive',
              editor.message_climax_passive,
            )}
            {renderCustomDropdown(
              'Receiver Climax Result',
              'passive_climax_location',
              editor.passive_climax_location,
              custom.climax_options,
            )}
          </LabeledList>
        </Section>
      </>
    );
  };

  const renderCustomSelector = (entry: CustomSelectorEntry, action: string) => (
    <Button
      key={entry.id}
      fluid
      mb={0.5}
      selected={asBool(entry.selected)}
      tooltip={entry.summary}
      onClick={() => act(action, { id: entry.id })}
    >
      <Box bold>{entry.name}</Box>
      <Box fontSize="10px" style={{ opacity: 0.85 }}>
        {entry.summary}
      </Box>
    </Button>
  );

  const renderCustomActions = () => {
    const custom = data.custom || ({} as CustomData);
    return (
      <Stack fill>
        <Stack.Item basis="230px" shrink={0}>
          <Section fill scrollable>
            <Section title="Templates" fitted mb={1}>
              {(custom.templates ?? []).map((entry) =>
                renderCustomSelector(entry, 'custom_select_template'),
              )}
            </Section>
            <Section title="Saved Actions" fitted>
              {(custom.saved ?? []).length ? (
                custom.saved.map((entry) =>
                  renderCustomSelector(entry, 'custom_select_saved'),
                )
              ) : (
                <Box color="label" fontSize="11px" italic>
                  You have not saved any custom actions yet.
                </Box>
              )}
            </Section>
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section fill scrollable>
            {renderCustomEditor()}
          </Section>
        </Stack.Item>
      </Stack>
    );
  };

  const erpAct = (
    prefType: string,
    action: string,
    extra?: Record<string, unknown>,
  ) => {
    act('erp_pref', {
      pref_type: prefType,
      action,
      ...(extra || {}),
    });
  };

  const renderErpControl = (pref: ErpPrefEntry, locked: boolean) => {
    if (pref.kind === 'flags') {
      return (
        <Box style={{ display: 'flex', flexWrap: 'wrap' }}>
          {(pref.flags ?? []).map((flag) => (
            <Button
              key={flag.bit}
              mr={0.5}
              mb={0.5}
              compact
              disabled={locked}
              selected={asBool(flag.on)}
              tooltip={flag.description || flag.name}
              onClick={() =>
                erpAct(pref.type, 'toggle_flag', { flag: flag.bit })
              }
            >
              {flag.name}
            </Button>
          ))}
        </Box>
      );
    }
    if (pref.kind === 'number') {
      return (
        <Stack align="center">
          <Stack.Item>
            <Button
              compact
              icon="chevron-left"
              disabled={locked}
              onClick={() => erpAct(pref.type, 'decrease')}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              disabled={locked}
              tooltip={`${pref.min} - ${pref.max}`}
              onClick={() => erpAct(pref.type, 'set')}
            >
              {String(pref.value ?? 0)}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              icon="chevron-right"
              disabled={locked}
              onClick={() => erpAct(pref.type, 'increase')}
            />
          </Stack.Item>
        </Stack>
      );
    }
    if (pref.kind === 'choice') {
      return (
        <Stack align="center">
          <Stack.Item>
            <Button
              compact
              icon="chevron-left"
              disabled={locked}
              onClick={() => erpAct(pref.type, 'prev')}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              disabled={locked}
              onClick={() => erpAct(pref.type, 'choose')}
            >
              {String(pref.value ?? 'None')}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              icon="chevron-right"
              disabled={locked}
              onClick={() => erpAct(pref.type, 'next')}
            />
          </Stack.Item>
        </Stack>
      );
    }
    return (
      <Button
        compact
        disabled={locked}
        selected={asBool(pref.value as Booleanish)}
        color={asBool(pref.value as Booleanish) ? 'good' : 'bad'}
        onClick={() => erpAct(pref.type, 'toggle')}
      >
        {asBool(pref.value as Booleanish) ? 'Enabled' : 'Disabled'}
      </Button>
    );
  };

  const renderErpValue = (pref: ErpPrefEntry) => {
    if (pref.kind === 'flags') {
      const onFlags = (pref.flags ?? []).filter((flag) => asBool(flag.on));
      return (
        <Box color="label">
          {onFlags.length
            ? onFlags.map((flag) => flag.name).join(', ')
            : 'None'}
        </Box>
      );
    }
    if (pref.kind === 'bool') {
      return (
        <Box bold color={asBool(pref.value as Booleanish) ? 'good' : 'bad'}>
          {asBool(pref.value as Booleanish) ? 'Enabled' : 'Disabled'}
        </Box>
      );
    }
    return <Box bold>{String(pref.value ?? 'None')}</Box>;
  };

  const renderErpColumn = (
    categories: ErpCategory[],
    editable: boolean,
    locked: boolean,
  ) => (
    <>
      {categories.length ? (
        categories.map((category) => (
          <Section key={category.name} title={category.name} fitted mb={1}>
            {(category.prefs ?? []).map((pref) => (
              <Stack key={pref.type} align="baseline" mb={0.75}>
                <Stack.Item grow basis={0}>
                  <Box bold>{pref.name}</Box>
                  <Box color="label" fontSize="11px">
                    {pref.description}
                  </Box>
                </Stack.Item>
                <Stack.Item basis="45%">
                  {editable
                    ? renderErpControl(pref, locked)
                    : renderErpValue(pref)}
                </Stack.Item>
              </Stack>
            ))}
          </Section>
        ))
      ) : (
        <Box color="label" textAlign="center" p={2} italic>
          No preferences available.
        </Box>
      )}
    </>
  );

  const renderPreferences = () => {
    const intimacy = data.intimacy || ({} as IntimacyData);
    const locked = !!intimacy.lock_reason;
    return (
      <Section fill scrollable>
        {intimacy.lock_reason ? (
          <NoticeBox mb={1}>{intimacy.lock_reason}</NoticeBox>
        ) : null}
        <Stack>
          {/* minWidth 0 lets the flex columns shrink below their content's
              min-content width; without it the pane overflows horizontally
              and the left edge scrolls out of view. */}
          <Stack.Item grow basis={0} style={{ minWidth: 0 }}>
            <Section title="Your Preferences" fitted>
              {renderErpColumn(intimacy.yours ?? [], true, locked)}
            </Section>
          </Stack.Item>
          <Stack.Item grow basis={0} style={{ minWidth: 0 }}>
            <Section
              title={
                asBool(data.is_self)
                  ? 'Your Preferences (Partner View)'
                  : `${data.target_name}'s Preferences`
              }
              fitted
            >
              {renderErpColumn(
                asBool(data.is_self)
                  ? (intimacy.yours ?? [])
                  : (intimacy.theirs ?? []),
                false,
                true,
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Section>
    );
  };

  const renderKinks = () => {
    const categories = data.intimacy?.their_kinks ?? [];
    return (
      <Section fill scrollable>
        {categories.length ? (
          categories.map((category) => (
            <Section key={category.name} title={category.name} fitted mb={1}>
              {category.kinks.map((kink) => (
                <Box key={kink.name} mb={0.75}>
                  <Stack align="baseline">
                    <Stack.Item grow>
                      <Box bold>{kink.name}</Box>
                    </Stack.Item>
                    <Stack.Item>
                      <Box color="pink" bold fontSize="11px">
                        {INTENSITY_LABELS[kink.intensity - 1] || 'Unknown'}
                      </Box>
                    </Stack.Item>
                  </Stack>
                  <Box color="label" fontSize="11px">
                    {kink.description}
                  </Box>
                  {kink.notes ? (
                    <Box color="average" fontSize="11px" italic>
                      Notes: {kink.notes}
                    </Box>
                  ) : null}
                </Box>
              ))}
            </Section>
          ))
        ) : (
          <Box color="label" textAlign="center" p={2} italic>
            No kink preferences found for this character.
          </Box>
        )}
      </Section>
    );
  };

  const submitNote = () => {
    if (!noteTitle.trim() || !noteContent.trim()) {
      return;
    }
    act('note_add', { title: noteTitle.trim(), content: noteContent.trim() });
    setNoteTitle('');
    setNoteContent('');
    setNoteFormOpen(false);
  };

  const renderNoteCard = (note: NoteEntry, editable: boolean) => (
    <Section key={note.title} fitted mb={0.75}>
      <Stack align="center">
        <Stack.Item grow>
          <Box bold>{note.title}</Box>
        </Stack.Item>
        {editable ? (
          <>
            <Stack.Item>
              <Button
                compact
                icon="pen"
                onClick={() => {
                  setEditingNote(note.title);
                  setEditContent(note.content);
                }}
              >
                Edit
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button.Confirm
                compact
                icon="trash"
                color="bad"
                confirmContent="Remove?"
                onClick={() => act('note_remove', { title: note.title })}
              >
                Remove
              </Button.Confirm>
            </Stack.Item>
          </>
        ) : null}
      </Stack>
      {editable && editingNote === note.title ? (
        <>
          <TextArea
            value={editContent}
            height="70px"
            onChange={setEditContent}
          />
          <Stack mt={0.5}>
            <Stack.Item grow />
            <Stack.Item>
              <Button
                compact
                color="good"
                icon="save"
                onClick={() => {
                  act('note_edit', {
                    title: note.title,
                    content: editContent,
                  });
                  setEditingNote(null);
                }}
              >
                Save
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button compact icon="times" onClick={() => setEditingNote(null)}>
                Cancel
              </Button>
            </Stack.Item>
          </Stack>
        </>
      ) : (
        <Box color="label" style={{ whiteSpace: 'pre-wrap' }}>
          {note.content}
        </Box>
      )}
      <Box color="grey" fontSize="10px" mt={0.5}>
        {note.meta}
      </Box>
    </Section>
  );

  const renderNotes = () => {
    const notes = data.notes || ({ yours: [], theirs: [] } as NotesData);
    const shownNotes = notesTab === 'yours' ? notes.yours : notes.theirs;
    return (
      <Section fill scrollable>
        <Tabs>
          <Tabs.Tab
            selected={notesTab === 'yours'}
            onClick={() => setNotesTab('yours')}
          >
            Your Notes About {data.target_name}
          </Tabs.Tab>
          <Tabs.Tab
            selected={notesTab === 'theirs'}
            onClick={() => setNotesTab('theirs')}
          >
            {asBool(data.is_self)
              ? 'Your Shared Notes'
              : `${data.target_name}'s Shared Notes`}
          </Tabs.Tab>
        </Tabs>
        {notesTab === 'yours' ? (
          <Box mb={1}>
            <Button
              icon={noteFormOpen ? 'times' : 'plus'}
              onClick={() => setNoteFormOpen(!noteFormOpen)}
            >
              {noteFormOpen ? 'Cancel' : `Add Note About ${data.target_name}`}
            </Button>
            {noteFormOpen ? (
              <Section fitted mt={0.5}>
                <Input
                  fluid
                  mb={0.5}
                  placeholder="Note title…"
                  value={noteTitle}
                  onChange={setNoteTitle}
                />
                <TextArea
                  height="70px"
                  placeholder="Write your note here…"
                  value={noteContent}
                  onChange={setNoteContent}
                />
                <Stack mt={0.5}>
                  <Stack.Item grow />
                  <Stack.Item>
                    <Button
                      icon="save"
                      color="good"
                      disabled={!noteTitle.trim() || !noteContent.trim()}
                      onClick={submitNote}
                    >
                      Save Note
                    </Button>
                  </Stack.Item>
                </Stack>
              </Section>
            ) : null}
          </Box>
        ) : null}
        {shownNotes.length ? (
          shownNotes.map((note) => renderNoteCard(note, notesTab === 'yours'))
        ) : (
          <Box color="label" textAlign="center" p={2} italic>
            {notesTab === 'yours'
              ? `You haven't written any notes about ${data.target_name} yet.`
              : 'No shared notes yet.'}
          </Box>
        )}
      </Section>
    );
  };

  const renderActiveTab = () => {
    switch (activeTab) {
      case 'bellyriding':
        return renderBellyriding();
      case 'custom':
        return renderCustomActions();
      case 'preferences':
        return renderPreferences();
      case 'kinks':
        return renderKinks();
      case 'notes':
        return renderNotes();
      default:
        return renderInteractions();
    }
  };

  return (
    <Window title="Sate Desire" width={900} height={560} theme="vanderlin">
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>{renderHeader()}</Stack.Item>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                icon="heart"
                selected={activeTab === 'interactions'}
                onClick={() => setTab('interactions')}
              >
                Interactions
              </Tabs.Tab>
              {hasBelly ? (
                <Tabs.Tab
                  icon="person-breastfeeding"
                  selected={activeTab === 'bellyriding'}
                  onClick={() => setTab('bellyriding')}
                >
                  Bellyriding
                </Tabs.Tab>
              ) : null}
              <Tabs.Tab
                icon="pen"
                selected={activeTab === 'custom'}
                onClick={() => setTab('custom')}
              >
                Custom Actions
              </Tabs.Tab>
              <Tabs.Tab
                icon="sliders-h"
                selected={activeTab === 'preferences'}
                onClick={() => setTab('preferences')}
              >
                Preferences
              </Tabs.Tab>
              <Tabs.Tab
                icon="star"
                selected={activeTab === 'kinks'}
                onClick={() => setTab('kinks')}
              >
                Kinks
              </Tabs.Tab>
              <Tabs.Tab
                icon="sticky-note"
                selected={activeTab === 'notes'}
                onClick={() => setTab('notes')}
              >
                Notes
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>{renderActiveTab()}</Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

export default SexScene;
