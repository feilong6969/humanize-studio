// Optional Node.js AI backend. Never expose API keys in browser code.
const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const PORT=Number(process.env.PORT)||3000;
const KEY=process.env.OPENAI_API_KEY;
const styles={natural:'Conversational and natural.',casual:'Friendly and informal.',simple:'Clear, concise, and easy to understand.',professional:'Polished, professional, and warm.'};
const languages={auto:'Keep the input language.',en:'Use English.',ja:'Use Japanese.'};
const send=(res,code,data,type='application/json; charset=utf-8')=>{res.writeHead(code,{'content-type':type,'cache-control':'no-store'});res.end(typeof data==='string'?data:JSON.stringify(data))};
http.createServer(async(req,res)=>{
 if(req.method==='GET'&&(req.url==='/'||req.url==='/index.html'))return send(res,200,fs.readFileSync(path.join(__dirname,'index.html')),'text/html; charset=utf-8');
 if(req.method!=='POST'||req.url!=='/api/rewrite')return send(res,404,{error:'Not found'});
 if(!KEY)return send(res,503,{error:'AI backend not configured'});
 try{
  let raw='';for await(const part of req){raw+=part;if(raw.length>100000)throw Error('Too long')}
  const {text,tone='natural',language='auto'}=JSON.parse(raw);
  if(typeof text!=='string'||!text.trim()||text.length>20000)return send(res,400,{error:'Text must be 1–20,000 characters.'});
  const upstream=await fetch('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:'Bearer '+KEY,'Content-Type':'application/json'},body:JSON.stringify({model:process.env.OPENAI_MODEL||'gpt-4.1-mini',instructions:'Rewrite the text to sound natural without changing meaning, facts, names, or citations. Do not fabricate information or intentionally add mistakes. '+(styles[tone]||styles.natural)+' '+(languages[language]||languages.auto)+' Return only the revised passage.',input:text,max_output_tokens:2500})});
  if(!upstream.ok)return send(res,502,{error:'AI service failed'});
  const data=await upstream.json();
  const result=(data.output||[]).flatMap(item=>item.content||[]).filter(item=>item.type==='output_text').map(item=>item.text).join('');
  return result?send(res,200,{text:result}):send(res,502,{error:'Empty response'});
 }catch{return send(res,400,{error:'Request could not be processed'})}
}).listen(PORT,()=>console.log('Humanize Studio: http://localhost:'+PORT));