import {NextResponse} from 'next/server';
import {createClient} from '@supabase/supabase-js';
export async function POST(req:Request){
 const sub=await req.json(); const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.SUPABASE_SERVICE_ROLE_KEY;
 if(!url||!key)return NextResponse.json({error:'Supabase no configurado'},{status:503});
 const token=req.headers.get('authorization')?.replace('Bearer ',''); if(!token)return NextResponse.json({error:'Sesión requerida'},{status:401});
 const db=createClient(url,key); const {data:{user},error}=await db.auth.getUser(token);
 if(error||!user)return NextResponse.json({error:'No autorizado'},{status:401});
 const {error:saveError}=await db.from('push_subscriptions').upsert({user_id:user.id,subscription:sub,endpoint:sub.endpoint});
 if(saveError)return NextResponse.json({error:saveError.message},{status:500}); return NextResponse.json({ok:true});
}
