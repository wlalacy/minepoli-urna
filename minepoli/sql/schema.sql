create extension if not exists pgcrypto;

create table if not exists elections (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 status text not null default 'closed' check (status in ('open','closed')),
 starts_at timestamptz,
 ends_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists candidates (
 id uuid primary key default gen_random_uuid(),
 election_id uuid not null references elections(id) on delete cascade,
 number integer not null,
 name text not null,
 party text not null default '',
 vice text not null default '',
 slogan text not null default '',
 photo_url text,
 description text not null default '',
 created_at timestamptz not null default now(),
 unique(election_id, number)
);
create table if not exists voters (
 id uuid primary key default gen_random_uuid(),
 election_id uuid not null references elections(id) on delete cascade,
 nickname text not null,
 cpv text not null,
 has_voted boolean not null default false,
 created_at timestamptz not null default now(),
 voted_at timestamptz,
 unique(election_id, cpv)
);
create table if not exists votes (
 id uuid primary key default gen_random_uuid(),
 election_id uuid not null references elections(id) on delete cascade,
 candidate_id uuid not null references candidates(id) on delete restrict,
 created_at timestamptz not null default now(),
 protocol text not null unique
);
create table if not exists admin_logs (
 id uuid primary key default gen_random_uuid(),
 action text not null,
 created_at timestamptz not null default now()
);

create index if not exists idx_candidates_election on candidates(election_id);
create index if not exists idx_voters_election on voters(election_id);
create index if not exists idx_votes_election on votes(election_id);

insert into elections(name,status) select 'Eleição do Realm MINEPOLI','closed'
where not exists (select 1 from elections);

alter table elections enable row level security;
alter table candidates enable row level security;
alter table voters enable row level security;
alter table votes enable row level security;
alter table admin_logs enable row level security;

create or replace function register_minepoli_vote(p_election uuid,p_cpv text,p_candidate uuid)
returns table(protocol text) language plpgsql security definer as $$
declare v_candidate uuid; v_protocol text;
begin
 if not exists(select 1 from elections where id=p_election and status='open' and (starts_at is null or starts_at<=now()) and (ends_at is null or ends_at>=now())) then raise exception 'ELECTION_CLOSED'; end if;
 select id into v_candidate from candidates where id=p_candidate and election_id=p_election;
 if v_candidate is null then raise exception 'INVALID_CANDIDATE'; end if;
 update voters set has_voted=true,voted_at=now() where election_id=p_election and cpv=p_cpv and has_voted=false;
 if not found then raise exception 'ALREADY_VOTED'; end if;
 v_protocol := 'MP-' || upper(substr(encode(gen_random_bytes(4),'hex'),1,8));
 insert into votes(election_id,candidate_id,protocol) values(p_election,v_candidate,v_protocol);
 return query select v_protocol;
exception when unique_violation then raise exception 'ALREADY_VOTED';
end; $$;
