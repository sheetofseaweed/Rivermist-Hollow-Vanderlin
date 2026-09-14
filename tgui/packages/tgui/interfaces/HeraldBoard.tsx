import type { CSSProperties } from 'react';
import { useState } from 'react';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const POSTING_TIER_NOTICE = 'notice';
const POSTING_TIER_LISTING = 'listing';
type PostingTier = typeof POSTING_TIER_NOTICE | typeof POSTING_TIER_LISTING;

type Posting = {
  posting_id: string;
  tier: PostingTier;
  title: string;
  body: string;
  poster_name: string;
  poster_title: string;
  signature_attested: BooleanLike;
  posted_at_label: string;
  expires_in_label: string;
  is_own: BooleanLike;
  can_authority_remove: BooleanLike;
};

type ScoutRegion = {
  region_name: string;
  danger_level: string;
  danger_color: string;
};

type HeraldBoardData = {
  postings: Posting[];
  scout_regions: ScoutRegion[];
  can_post_listing: BooleanLike;
  can_authority_remove: BooleanLike;
  user_default_name: string;
  user_default_role: string;
  has_active_notice: BooleanLike;
  has_active_listing: BooleanLike;
};

type TabKey = 'postings' | 'scouts';

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

const postingGridStyle: CSSProperties = {
  display: 'grid',
  gridTemplateColumns: '1fr 1fr',
  gap: 10,
  alignItems: 'start',
};

const inkButton = (disabled?: boolean): CSSProperties => ({
  fontFamily: SERIF,
  fontSize: FONT_BODY,
  color: disabled ? INK_FAINT : INK,
  background: 'var(--p-button-bg)',
  border: `1px solid ${INK_SOFT}`,
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
  minWidth: '90px',
  textAlign: 'center',
  padding: '2px 8px',
  borderRadius: '2px',
  fontWeight: 'bold',
  fontSize: FONT_BODY,
  color: '#1a1208',
  background: color,
  border: `1px solid ${INK_SOFT}`,
});

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
          </div>

          {tab === 'postings' && <PostingsTab data={data} act={act} />}
          {tab === 'scouts' && <ScoutTab regions={data.scout_regions} />}
        </div>
      </Window.Content>
    </Window>
  );
};

const PostingsTab = ({ data, act }: { data: HeraldBoardData; act: ActFn }) => {
  const [showForm, setShowForm] = useState(false);

  const listings = data.postings.filter((p) => p.tier === POSTING_TIER_LISTING);
  const notices = data.postings.filter((p) => p.tier === POSTING_TIER_NOTICE);

  return (
    <>
      <div style={{ textAlign: 'right', marginBottom: 8 }}>
        <button type="button" style={inkButton()} onClick={() => setShowForm(!showForm)}>
          {showForm ? 'Hide Form' : 'Make a Posting'}
        </button>
      </div>

      {showForm && <PostingForm data={data} act={act} onClose={() => setShowForm(false)} />}

      <div style={sectionHeaderStyle}>Standing Listings</div>
      {listings.length === 0 ? (
        <EmptyMessage text="No standing listings have been pinned." />
      ) : (
        <div style={postingGridStyle}>
          {listings.map((p) => (
            <PostingCard key={p.posting_id} posting={p} act={act} />
          ))}
        </div>
      )}

      <hr style={rulerStyle} />

      <div style={sectionHeaderStyle}>Notices</div>
      {notices.length === 0 ? (
        <EmptyMessage text="No notices on the board. The wind stirs the empty parchments." />
      ) : (
        <div style={postingGridStyle}>
          {notices.map((p) => (
            <PostingCard key={p.posting_id} posting={p} act={act} />
          ))}
        </div>
      )}
    </>
  );
};

const ScoutTab = ({ regions }: { regions: ScoutRegion[] }) => {
  return (
    <>
      <div style={sectionHeaderStyle}>Word from the Scouts</div>
      <div style={{ color: INK_SOFT, fontStyle: 'italic', textAlign: 'center', marginBottom: 10 }}>
        What danger stirs in the lands around us, as best it's known.
      </div>
      {regions.length === 0 ? (
        <EmptyMessage text="No word from the scouts yet." />
      ) : (
        <div style={{ ...postingGridStyle, gridTemplateColumns: '1fr' }}>
          {regions.map((r) => (
            <div
              key={r.region_name}
              style={{
                ...cardStyle,
                marginBottom: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <div style={{ fontSize: FONT_TITLE, fontWeight: 'bold', color: INK, fontFamily: SERIF }}>
                {r.region_name}
              </div>
              <div style={dangerBadgeStyle(r.danger_color)}>{r.danger_level}</div>
            </div>
          ))}
        </div>
      )}
    </>
  );
};

const EmptyMessage = ({ text }: { text: string }) => (
  <div style={{ color: INK_FAINT, textAlign: 'center', padding: '12px 0' }}>{text}</div>
);

type ActFn = (action: string, params?: Record<string, unknown>) => void;

const PostingCard = ({ posting, act }: { posting: Posting; act: ActFn }) => {
  const isListing = posting.tier === POSTING_TIER_LISTING;
  return (
    <div
      style={{
        ...cardStyle,
        marginBottom: 0,
        background: isListing ? 'rgba(200,170,100,0.18)' : 'var(--p-card-bg)',
        borderColor: isListing ? INK_SOFT : INK_FAINT,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'baseline' }}>
        <div style={{ flex: 1, fontSize: FONT_TITLE, fontWeight: 'bold', color: INK, fontFamily: SERIF }}>
          {posting.title}
        </div>
        <div style={{ color: INK_FAINT, fontSize: FONT_BODY }}>
          {posting.posted_at_label}
          {posting.expires_in_label && ` \u00b7 expires ${posting.expires_in_label}`}
        </div>
      </div>

      {isListing && <div style={{ color: SEAL_AMBER, fontSize: FONT_BODY, marginTop: '2px' }}>Standing Listing</div>}

      <div style={{ marginTop: '6px', marginBottom: '6px', whiteSpace: 'pre-wrap', color: INK }}>{posting.body}</div>

      <div style={{ display: 'flex', alignItems: 'center', marginTop: '6px' }}>
        <div style={{ flex: 1, color: INK_SOFT, fontStyle: 'italic', fontSize: FONT_BODY }}>
          - {posting.poster_name}
          {posting.poster_title && `, ${posting.poster_title}`}
          {!posting.signature_attested && (
            <span style={{ color: INK_FAINT, fontSize: FONT_BODY, marginLeft: '6px' }}>(unattested, yet)</span>
          )}
        </div>
        {!!posting.is_own && (
          <button type="button" style={inkButton()} onClick={() => act('remove_post', { posting_id: posting.posting_id })}>
            Take Down
          </button>
        )}
        {!posting.is_own && !!posting.can_authority_remove && (
          <button
            type="button"
            style={inkButton()}
            onClick={() => act('authority_remove_post', { posting_id: posting.posting_id })}
          >
            Remove (Authority)
          </button>
        )}
      </div>
    </div>
  );
};

const PostingForm = ({ data, act, onClose }: { data: HeraldBoardData; act: ActFn; onClose: () => void }) => {
  const [tier, setTier] = useState<PostingTier>(POSTING_TIER_NOTICE);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [posterName, setPosterName] = useState(data.user_default_name || '');
  const [posterTitle, setPosterTitle] = useState(data.user_default_role || '');

  const titleValid = title.length > 0 && title.length <= TITLE_MAX;
  const bodyValid = body.length > 0 && body.length <= BODY_MAX;
  const nameValid = posterName.length > 0 && posterName.length <= NAME_MAX;
  const roleValid = posterTitle.length <= ROLE_MAX;
  const valid = titleValid && bodyValid && nameValid && roleValid;

  const willReplaceNotice = tier === POSTING_TIER_NOTICE && !!data.has_active_notice;
  const willReplaceListing = tier === POSTING_TIER_LISTING && !!data.has_active_listing;

  const onPost = () => {
    if (!valid) {
      return;
    }
    if (willReplaceListing) {
      const ok = confirm('You already have a Standing Listing posted. Posting a new one will replace it. Proceed?');
      if (!ok) {
        return;
      }
    }
    act('make_post', { tier, title, body, poster_name: posterName, poster_title: posterTitle });
    onClose();
  };

  return (
    <div style={{ ...cardStyle, borderColor: INK_SOFT }}>
      <div style={sectionHeaderStyle}>Pin a Posting</div>

      {!!data.can_post_listing && (
        <div style={{ marginBottom: 10 }}>
          <div style={fieldLabelStyle}>Kind of posting</div>
          <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
            <button
              type="button"
              style={{
                ...inkButton(),
                fontWeight: tier === POSTING_TIER_NOTICE ? 'bold' : 'normal',
                background: tier === POSTING_TIER_NOTICE ? 'var(--p-tab-active-bg)' : 'var(--p-button-bg)',
              }}
              onClick={() => setTier(POSTING_TIER_NOTICE)}
            >
              Notice (expires in 30m)
            </button>
            <button
              type="button"
              style={{
                ...inkButton(),
                fontWeight: tier === POSTING_TIER_LISTING ? 'bold' : 'normal',
                background: tier === POSTING_TIER_LISTING ? 'var(--p-tab-active-bg)' : 'var(--p-button-bg)',
              }}
              onClick={() => setTier(POSTING_TIER_LISTING)}
            >
              Standing Listing (no expiry)
            </button>
          </div>
        </div>
      )}

      <FormField label="Title" value={title} onChange={setTitle} max={TITLE_MAX} />
      <FormField label="Body" value={body} onChange={setBody} max={BODY_MAX} multiline />
      <FormField label="Signed as" value={posterName} onChange={setPosterName} max={NAME_MAX} />
      <FormField label="Title or role" value={posterTitle} onChange={setPosterTitle} max={ROLE_MAX} optional />

      {willReplaceNotice && (
        <div style={{ color: SEAL_AMBER, fontSize: FONT_BODY, marginTop: 6 }}>
          You have a Notice already posted. Pinning this will take it down.
        </div>
      )}
      {willReplaceListing && (
        <div style={{ color: SEAL_AMBER, fontSize: FONT_BODY, marginTop: 6 }}>
          You have a Standing Listing already posted. Pinning this will take it down.
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 6, marginTop: 10 }}>
        <button type="button" style={inkButton()} onClick={onClose}>
          Cancel
        </button>
        <button type="button" style={inkButton(!valid)} disabled={!valid} onClick={onPost}>
          Pin Posting
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
