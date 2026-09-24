-- Run once in the Supabase dashboard: SQL Editor -> New query -> Run.
-- Public-read bucket for lesson PDF/PPTX, 25MB cap, only these two types.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'lesson-content',
  'lesson-content',
  true,
  26214400,
  array[
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation'
  ]
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Uploads with the anon key, limited to this bucket. Not teacher-only yet.
drop policy if exists "lesson-content insert" on storage.objects;
create policy "lesson-content insert" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'lesson-content');

-- x-upsert (re-uploading the same file name) needs update permission too.
drop policy if exists "lesson-content update" on storage.objects;
create policy "lesson-content update" on storage.objects
  for update to anon, authenticated
  using (bucket_id = 'lesson-content')
  with check (bucket_id = 'lesson-content');
