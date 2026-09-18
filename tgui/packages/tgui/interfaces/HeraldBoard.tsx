//RMH EDITED - new file: TGUI panel for /obj/structure/fake_machine/heraldboard.
//Backend lives under modular_rmh/code/game/objects/structures/fake_machines/heraldboard.dm -
//this interface file itself stays in the shared tgui/ tree (this fork has no
//separate modular tgui folder; new fork interfaces just live alongside the rest).
//
//Ported from Azure (Twilight-Axis)'s Noticeboard, then reworked for RMH: posts
//are permanent (they die with their author's character, not on a timer), rights
//come from the modular RMH town hierarchy, and Scout Reports reads RMH's own
//SSregionthreat rather than Azure's economy stack.
import type { CSSProperties } from 'react';
import { useState } from 'react';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Posting = {
  posting_id: string;
  title: string;
  body: string;
  poster_name: string;
  poster_title: string;
  signature_attested: BooleanLike;
  posted_at_label: string;
  is_own: BooleanLike;
  can_authority_remove: BooleanLike;
  /// 0 = no mark, 1..3 = stars, 4 = the herald's quill
  shown_rank: number;
  /// true when the herald is seeing through an unattested signature
  rank_hidden: BooleanLike;
};

type ScoutRegion = {
  region_name: string;
  danger_level: string;
  danger_color: string;
  region_desc: string;
};

type PruneEntry = {
  remover_name: string;
  remover_title: string;
  post_title: string;
  poster_name: string;
  when_label: string;
};

type HeraldBoardData = {
  posts: Posting[];
  scout_regions: ScoutRegion[];
  prune_log: PruneEntry[];
  viewer_rank: number;
  is_herald: BooleanLike;
  can_see_prune: BooleanLike;
  user_default_name: string;
  user_default_role: string;
  post_count: number;
  post_limit: number;
};

type TabKey = 'postings' | 'scouts' | 'prune';

const RANK_HERALD = 4;

// Must match HERALDBOARD_POST_COOLDOWN / HERALDBOARD_REMOVE_COOLDOWN in the DM
// file. This is only to grey the buttons out - the server enforces the real limit.
const POST_COOLDOWN_MS = 5000;
const REMOVE_COOLDOWN_MS = 2000;

// Parchment style tokens (consume --p-* vars from the parchment theme, same
// tokens Navigator.tsx and Stockpile.tsx already draw from).
const SERIF = '"Lora", Georgia, serif';
const FONT_BODY = 'var(--p-font-body)';
const FONT_TITLE = 'var(--p-font-title)';
const INK = 'var(--p-ink)';
const INK_SOFT = 'var(--p-ink-soft)';
const INK_FAINT = 'var(--p-ink-faint)';
const SEAL_RED = 'var(--p-seal-red)';
const SEAL_AMBER = 'var(--p-seal-amber)';
const TITLE = 'var(--p-title)';
const TITLE_FONT = 'var(--p-title-font)';

const NAME_MAX = 50;
const ROLE_MAX = 50;
const TITLE_MAX = 50;
const BODY_MAX = 500;

const pageStyle: CSSProperties = {
  position: 'relative',
  minHeight: '100%',
  padding: '16px 28px 24px 28px',
  fontFamily: SERIF,
  color: INK,
  fontSize: FONT_BODY,
  lineHeight: 1.5,
};

const titleStyle: CSSProperties = {
  textAlign: 'center',
  fontSize: '20px',
  fontWeight: 'bold',
  fontFamily: TITLE_FONT,
  color: TITLE,
  margin: '0 0 4px 0',
};

const subtitleStyle: CSSProperties = {
  textAlign: 'center',
  color: INK_SOFT,
  fontStyle: 'italic',
  fontSize: FONT_BODY,
};

const rulerStyle: CSSProperties = {
  height: '1px',
  background: `linear-gradient(90deg, transparent 0%, ${INK_FAINT} 20%, ${INK_FAINT} 80%, transparent 100%)`,
  border: 'none',
  margin: '10px 0 14px 0',
};

const cardStyle: CSSProperties = {
  background: 'var(--p-card-bg)',
  border: `1px solid ${INK_FAINT}`,
  borderRadius: '2px',
  padding: '10px 14px',
  marginBottom: '12px',
  boxShadow: '1px 1px 4px var(--p-card-shadow)',
  // A grid item's default min-width is auto (content-based), so an unbroken
  // long word can force the whole column wider than its track. minWidth: 0
  // lets the card actually shrink to the track's width, and the two
  // wrap properties below then break the long word itself instead of
  // spilling past the card edge.
  minWidth: 0,
  overflowWrap: 'anywhere',
  wordBreak: 'break-word',
};

const sectionHeaderStyle: CSSProperties = {
  textAlign: 'center',
  color: SEAL_AMBER,
  fontWeight: 'bold',
  textTransform: 'uppercase',
  letterSpacing: '0.5px',
  fontSize: FONT_BODY,
  margin: '8px 0 8px 0',
};

// Responsive: cards flow into as many columns as fit, and reflow downward as
// the window narrows. No fixed column count anywhere.
const postingGridStyle: CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
  gap: 10,
  alignItems: 'start',
};

const scoutGridStyle: CSSProperties = {
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))',
  gap: 10,
  alignItems: 'stretch',
};

const inkButton = (disabled?: boolean): CSSProperties => ({
  fontFamily: SERIF,
  fontSize: FONT_BODY,
  color: disabled ? INK_FAINT : INK,
  background: 'var(--p-button-bg)',
  border: `1px solid ${disabled ? INK_FAINT : INK_SOFT}`,
  borderRadius: '2px',
  padding: '3px 10px',
  cursor: disabled ? 'default' : 'pointer',
});

const fieldLabelStyle: CSSProperties = { color: SEAL_AMBER, fontSize: FONT_BODY };

const tabBarStyle: CSSProperties = {
  display: 'flex',
  gap: 4,
  marginBottom: 10,
};

const tabStyle = (active: boolean): CSSProperties => ({
  flex: 1,
  textAlign: 'center',
  padding: '5px 0',
  fontFamily: SERIF,
  fontSize: FONT_BODY,
  fontWeight: active ? 'bold' : 'normal',
  color: active ? INK : INK_SOFT,
  background: active ? 'var(--p-tab-active-bg)' : 'var(--p-button-bg)',
  border: `1px solid ${INK_FAINT}`,
  borderRadius: '2px',
  cursor: 'pointer',
});

const dangerBadgeStyle = (color: string): CSSProperties => ({
  display: 'inline-block',
  padding: '2px 8px',
  borderRadius: '2px',
  fontWeight: 'bold',
  fontSize: FONT_BODY,
  color: '#1a1208',
  background: color,
  border: `1px solid ${INK_SOFT}`,
  whiteSpace: 'nowrap',
});

/// Rank mark drawn in the post's bottom-right corner: stars for the ranked
/// seats, a quill for the herald. Nothing at all for rank 0.
const RankMark = ({ rank, hidden }: { rank: number; hidden?: BooleanLike }) => {
  if (!rank) {
    return null;
  }
  const isHerald = rank >= RANK_HERALD;
  return (
    <div
      style={{
        color: SEAL_AMBER,
        fontSize: FONT_TITLE,
        letterSpacing: '1px',
        opacity: hidden ? 0.55 : 1,
        fontStyle: hidden ? 'italic' : 'normal',
        whiteSpace: 'nowrap',
      }}
      title={
        hidden
          ? "Unattested signature - only you can read this person's standing"
          : undefined
      }
    >
      {isHerald ? '\u2712' : '\u2605'.repeat(Math.min(rank, 3))}
    </div>
  );
};

export const HeraldBoard = () => {
  const { data, act } = useBackend<HeraldBoardData>();
  const [tab, setTab] = useState<TabKey>('postings');

  return (
    <Window title="Herald's Board" width={1000} height={760} theme="parchment">
      <Window.Content scrollable>
        <div style={pageStyle}>
          <div style={titleStyle}>The Herald&apos;s Board</div>
          <div style={subtitleStyle}>postings of the realm and her commons</div>
          <hr style={rulerStyle} />

          <div style={tabBarStyle}>
            <div style={tabStyle(tab === 'postings')} onClick={() => setTab('postings')}>
              Postings
            </div>
            <div style={tabStyle(tab === 'scouts')} onClick={() => setTab('scouts')}>
              Scout Reports
            </div>
            {!!data.can_see_prune && (
              <div style={tabStyle(tab === 'prune')} onClick={() => setTab('prune')}>
                Prune
              </div>
            )}
          </div>

          {tab === 'postings' && <PostingsTab data={data} act={act} />}
          {tab === 'scouts' && <ScoutTab regions={data.scout_regions} />}
          {tab === 'prune' && !!data.can_see_prune && <PruneTab entries={data.prune_log} />}
        </div>
      </Window.Content>
    </Window>
  );
};

const EmptyMessage = ({ text }: { text: string }) => (
  <div style={{ color: INK_FAINT, textAlign: 'center', padding: '12px 0' }}>{text}</div>
);

type ActFn = (action: string, params?: Record<string, unknown>) => void;

const PostingsTab = ({ data, act }: { data: HeraldBoardData; act: ActFn }) => {
  const [showForm, setShowForm] = useState(false);
  // Purely cosmetic mirror of the server cooldown, so the buttons visibly rest.
  const [busyUntil, setBusyUntil] = useState(0);
  const busy = Date.now() < busyUntil;

  const atLimit = data.post_count >= data.post_limit;

  const onRemove = (action: string, posting_id: string) => {
    if (busy) {
      return;
    }
    setBusyUntil(Date.now() + REMOVE_COOLDOWN_MS);
    act(action, { posting_id });
  };

  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ flex: 1, color: atLimit ? SEAL_RED : INK_SOFT, fontSize: FONT_BODY }}>
          Postings pinned: {data.post_count} / {data.post_limit}
          {atLimit && ' \u2014 take one down to pin another'}
        </div>
        <button
          type="button"
          style={inkButton()}
          onClick={() => setShowForm(!showForm)}
        >
          {showForm ? 'Hide Form' : 'Make a Posting'}
        </button>
      </div>

      {showForm && (
        <PostingForm
          data={data}
          act={act}
          busy={busy}
          onPosted={() => setBusyUntil(Date.now() + POST_COOLDOWN_MS)}
          onClose={() => setShowForm(false)}
        />
      )}

      {data.posts.length === 0 ? (
        <EmptyMessage text="No postings on the board. The wind stirs the empty parchments." />
      ) : (
        <div style={postingGridStyle}>
          {data.posts.map((p) => (
            <PostingCard key={p.posting_id} posting={p} busy={busy} onRemove={onRemove} />
          ))}
        </div>
      )}
    </>
  );
};

const PostingCard = ({
  posting,
  busy,
  onRemove,
}: {
  posting: Posting;
  busy: boolean;
  onRemove: (action: string, posting_id: string) => void;
}) => (
  <div style={{ ...cardStyle, marginBottom: 0, display: 'flex', flexDirection: 'column' }}>
    <div style={{ display: 'flex', alignItems: 'baseline' }}>
      <div
        style={{
          flex: 1,
          minWidth: 0,
          fontSize: FONT_TITLE,
          fontWeight: 'bold',
          color: INK,
          fontFamily: SERIF,
        }}
      >
        {posting.title}
      </div>
      <div style={{ color: INK_FAINT, fontSize: FONT_BODY, whiteSpace: 'nowrap' }}>
        {posting.posted_at_label}
      </div>
    </div>

    <div
      style={{
        marginTop: '6px',
        marginBottom: '6px',
        whiteSpace: 'pre-wrap',
        color: INK,
        flex: 1,
        minWidth: 0,
      }}
    >
      {posting.body}
    </div>

    <div style={{ display: 'flex', alignItems: 'flex-end', marginTop: '6px', gap: 6 }}>
      <div style={{ flex: 1, minWidth: 0, color: INK_SOFT, fontStyle: 'italic', fontSize: FONT_BODY }}>
        - {posting.poster_name}
        {posting.poster_title && `, ${posting.poster_title}`}
      </div>
      {!!posting.is_own && (
        <button
          type="button"
          style={inkButton(busy)}
          disabled={busy}
          onClick={() => onRemove('remove_post', posting.posting_id)}
        >
          Take Down
        </button>
      )}
      {!posting.is_own && !!posting.can_authority_remove && (
        <button
          type="button"
          style={inkButton(busy)}
          disabled={busy}
          onClick={() => onRemove('authority_remove_post', posting.posting_id)}
        >
          Remove
        </button>
      )}
      {/* bottom-right corner mark */}
      <RankMark rank={posting.shown_rank} hidden={posting.rank_hidden} />
    </div>
  </div>
);

const ScoutTab = ({ regions }: { regions: ScoutRegion[] }) => (
  <>
    <div style={sectionHeaderStyle}>Word from the Scouts</div>
    <div
      style={{
        color: INK_SOFT,
        fontStyle: 'italic',
        textAlign: 'center',
        marginBottom: 10,
      }}
    >
      What danger stirs in the lands around us, as best it&apos;s known.
    </div>
    {regions.length === 0 ? (
      <EmptyMessage text="No word from the scouts yet." />
    ) : (
      <div style={scoutGridStyle}>
        {regions.map((r) => (
          <div
            key={r.region_name}
            style={{
              ...cardStyle,
              marginBottom: 0,
              display: 'flex',
              flexDirection: 'column',
              gap: 6,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
              <div
                style={{
                  flex: 1,
                  minWidth: 0,
                  fontSize: FONT_TITLE,
                  fontWeight: 'bold',
                  color: INK,
                  fontFamily: SERIF,
                }}
              >
                {r.region_name}
              </div>
              <div style={dangerBadgeStyle(r.danger_color)}>{r.danger_level}</div>
            </div>
            <div style={{ color: INK_SOFT, fontSize: FONT_BODY }}>{r.region_desc}</div>
          </div>
        ))}
      </div>
    )}
  </>
);

const PruneTab = ({ entries }: { entries: PruneEntry[] }) => (
  <>
    <div style={sectionHeaderStyle}>Prunings</div>
    <div
      style={{
        color: INK_SOFT,
        fontStyle: 'italic',
        textAlign: 'center',
        marginBottom: 10,
      }}
    >
      Who tore down whose word, and when.
    </div>
    {entries.length === 0 ? (
      <EmptyMessage text="Nothing has been torn down yet." />
    ) : (
      <div>
        {entries.map((e, i) => (
          <div
            key={`${e.when_label}-${e.post_title}-${i}`}
            style={{ ...cardStyle, marginBottom: 8, display: 'flex', alignItems: 'baseline', gap: 8 }}
          >
            <div style={{ flex: 1, minWidth: 0, color: INK }}>
              <span style={{ fontWeight: 'bold' }}>{e.remover_name}</span>
              {e.remover_title && (
                <span style={{ color: INK_SOFT, fontStyle: 'italic' }}>, {e.remover_title}</span>
              )}
              <span style={{ color: INK_SOFT }}> took down </span>
              <span style={{ fontWeight: 'bold' }}>&laquo;{e.post_title}&raquo;</span>
              <span style={{ color: INK_SOFT }}> by {e.poster_name}</span>
            </div>
            <div style={{ color: INK_FAINT, fontSize: FONT_BODY, whiteSpace: 'nowrap' }}>
              {e.when_label}
            </div>
          </div>
        ))}
      </div>
    )}
  </>
);

const PostingForm = ({
  data,
  act,
  busy,
  onPosted,
  onClose,
}: {
  data: HeraldBoardData;
  act: ActFn;
  busy: boolean;
  onPosted: () => void;
  onClose: () => void;
}) => {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [posterName, setPosterName] = useState(data.user_default_name || '');
  const [posterTitle, setPosterTitle] = useState(data.user_default_role || '');

  const titleValid = title.length > 0 && title.length <= TITLE_MAX;
  const bodyValid = body.length > 0 && body.length <= BODY_MAX;
  const nameValid = posterName.length > 0 && posterName.length <= NAME_MAX;
  const roleValid = posterTitle.length <= ROLE_MAX;
  const atLimit = data.post_count >= data.post_limit;
  const valid = titleValid && bodyValid && nameValid && roleValid && !atLimit && !busy;

  // Signing under anything but your true name and real office hides your
  // standing from everyone except the herald.
  const attested =
    posterName === data.user_default_name && posterTitle === data.user_default_role;

  const onPost = () => {
    if (!valid) {
      return;
    }
    onPosted();
    act('make_post', {
      title,
      body,
      poster_name: posterName,
      poster_title: posterTitle,
    });
    onClose();
  };

  return (
    <div style={{ ...cardStyle, borderColor: INK_SOFT }}>
      <div style={sectionHeaderStyle}>Pin a Posting</div>

      <FormField label="Title" value={title} onChange={setTitle} max={TITLE_MAX} />
      <FormField label="Body" value={body} onChange={setBody} max={BODY_MAX} multiline />
      <FormField label="Signed as" value={posterName} onChange={setPosterName} max={NAME_MAX} />
      <FormField
        label="Title or role"
        value={posterTitle}
        onChange={setPosterTitle}
        max={ROLE_MAX}
        optional
      />

      {!attested && data.viewer_rank > 0 && (
        <div style={{ color: SEAL_AMBER, fontSize: FONT_BODY, marginTop: 6 }}>
          Signing under another name hides your standing - no mark will show on this
          posting, save to the Town Mouth.
        </div>
      )}
      {atLimit && (
        <div style={{ color: SEAL_RED, fontSize: FONT_BODY, marginTop: 6 }}>
          You already keep {data.post_limit} posting{data.post_limit === 1 ? '' : 's'} pinned.
          Take one down first.
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 6, marginTop: 10 }}>
        <button type="button" style={inkButton()} onClick={onClose}>
          Cancel
        </button>
        <button type="button" style={inkButton(!valid)} disabled={!valid} onClick={onPost}>
          {busy ? 'Ink drying\u2026' : 'Pin Posting'}
        </button>
      </div>
    </div>
  );
};

const FormField = ({
  label,
  value,
  onChange,
  max,
  multiline,
  optional,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  max: number;
  multiline?: boolean;
  optional?: boolean;
}) => {
  const overLimit = value.length > max;
  return (
    <div style={{ marginBottom: 8 }}>
      <div style={{ display: 'flex', alignItems: 'baseline' }}>
        <div style={{ ...fieldLabelStyle, flex: 1 }}>
          {label}
          {optional && <span style={{ color: INK_FAINT, marginLeft: 4 }}>(optional)</span>}
        </div>
        <div style={{ color: overLimit ? SEAL_RED : INK_FAINT, fontSize: FONT_BODY }}>
          {value.length} / {max}
        </div>
      </div>
      {multiline ? (
        <textarea
          value={value}
          onChange={(e) => onChange(e.target.value)}
          rows={5}
          style={{
            width: '100%',
            fontFamily: SERIF,
            fontSize: FONT_BODY,
            background: 'var(--p-button-bg)',
            border: `1px solid ${INK_FAINT}`,
            color: INK,
            padding: '4px 6px',
            resize: 'vertical',
          }}
        />
      ) : (
        <input
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          style={{
            width: '100%',
            fontFamily: SERIF,
            fontSize: FONT_BODY,
            background: 'var(--p-button-bg)',
            border: `1px solid ${INK_FAINT}`,
            color: INK,
            padding: '3px 6px',
          }}
        />
      )}
    </div>
  );
};
