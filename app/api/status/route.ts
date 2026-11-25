import {NextResponse} from 'next/server';
import {createClient} from '@supabase/supabase-js';
import webpush from 'web-push';
export async function POST(req:Request){
 const {status}=await req.json(); if(!['available','busy'].includes(status))return NextResponse.json({error:'Estado inválido'},{status:400});
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.SUPABASE_SERVICE_ROLE_KEY; if(!url||!key)return NextResponse.json({error:'Supabase no configurado'},{status:503});
 const token=req.headers.get('authorization')?.replace('Bearer ',''); if(!token)return NextResponse.json({error:'Sesión requerida'},{status:401});
 const db=createClient(url,key); const {data:{user},error}=await db.auth.getUser(token); if(error||!user)return NextResponse.json({error:'No autorizado'},{status:401});
 const {data:profile}=await db.from('profiles').select('display_name').eq('id',user.id).single();
 const {data:members}=await db.from('space_members').select('space_id').eq('user_id',user.id); const ids=(members??[]).map(m=>m.space_id); if(!ids.length)return NextResponse.json({ok:true,notified:0});
 const {data:others}=await db.from('space_members').select('user_id').in('space_id',ids).neq('user_id',user.id); const userIds=[...new Set((others??[]).map(x=>x.user_id))];
 const {data:subs}=await db.from('push_subscriptions').select('subscription').in('user_id',userIds);
 if(process.env.VAPID_PUBLIC_KEY&&process.env.VAPID_PRIVATE_KEY){webpush.setVapidDetails(process.env.VAPID_SUBJECT||'mailto:hello@synctogether.app',process.env.VAPID_PUBLIC_KEY,process.env.VAPID_PRIVATE_KEY);await Promise.all((subs??[]).map(s=>webpush.sendNotification(s.subscription,JSON.stringify({title:'SyncTogether',body:`${profile?.display_name||'Alguien'} ahora está ${status==='available'?'disponible':'ocupado'}.`,url:'/'})).catch(()=>null)));}
 return NextResponse.json({ok:true,notified:subs?.length??0});
}
