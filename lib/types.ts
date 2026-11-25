export type Availability = 'available' | 'busy';
export type Member = { id:string; user_id:string; display_name:string; status:Availability; status_note?:string|null; manual_status:boolean; avatar_url?:string|null };
export type Space = { id:string; name:string; invite_code:string; kind:'pair'|'group' };
