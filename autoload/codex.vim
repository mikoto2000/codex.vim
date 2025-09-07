" codex
" Version: 0.0.1
" Author: mikoto2000
" License: MIT

if exists('g:loaded_codex')
  finish
endif
let g:loaded_codex = 1

let s:save_cpo = &cpo
set cpo&vim

let s:HTTP = vital#codex#import("Web.HTTP")

let s:ENDPOINT_URL = "https://api.openai.com/v1/responses"
let s:HEADERS = {
      \  "Content-Type": "application/json",
      \  "Authorization": "Bearer " . $OPENAI_API_KEY
      \}
let s:MODEL = "gpt-5"

let s:prev_response_id = ''

" Request input専用バッファ名
let s:REQUEST_BUFFER_NAME = '__CODEX_REQUEST__'

function! codex#OpenRequestBuffer() abort
  " リクエスト入力専用バッファを新規作成/表示
  silent bo new __CODEX_REQUEST__

  setlocal noshowcmd
  setlocal noswapfile
  setlocal buftype=nofile
  setlocal nonumber
  setlocal ft=markdown
endfunction

function! codex#OpenCodexBuffer() abort
    """ 呼び出し元のウィンドウ ID を記憶
    let s:caller_window_id = win_getid()

    """ 新しいバッファを作成
    silent bo new __CODEX_BUFFER__

    """ バッファリスト用バッファの設定
    setlocal noshowcmd
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nonumber
    setlocal ft=markdown
endfunction

function! codex#AppendText(text) abort
  " 追記する行データを用意（文字列 or リストの両対応）
  let lines = type(a:text) == v:t_list ? a:text : split(a:text, "\n", 1)

  " codex 用バッファの特定（なければ作成）
  let name = '__CODEX_BUFFER__'
  let buf  = bufnr(name)
  if buf == -1
    call codex#OpenCodexBuffer()
    let buf  = bufnr(name)
  endif

  if !bufloaded(buf) | call bufload(buf) | endif


  " 末尾に追記（空バッファなら1行目を置換）
  let lc = getbufinfo(buf)[0].linecount
  if lc == 1 && getbufline(buf, 1)[0] ==# ''
    call setbufline(buf, 1, lines)
  else
    call appendbufline(buf, lc, lines)
  endif
endfunction

function! codex#ExitCb(job, code, headers, body) abort
  echomsg a:body
  let body_text = type(a:body) == v:t_list ? join(a:body, "\n") : a:body
  let body_json = json_decode(body_text)

  " レスポンスからテキストを抽出
  let text = s:ExtractText(body_json)

  " codex 用バッファに追記
  call codex#AppendText(text . "\n")

  " stateful 用に id を保持（あれば更新）
  if has_key(body_json, 'id') && type(body_json.id) == v:t_string && !empty(body_json.id)
    let s:prev_response_id = body_json.id
  endif
endfunction

function! codex#Request(text) abort
  let payload = {
        \   "model": s:MODEL,
        \   "input": a:text,
        \   "tools": [{'type': 'web_search'}]
        \ }

  if type(s:prev_response_id) == v:t_string && !empty(s:prev_response_id)
    let payload.previous_response_id = s:prev_response_id
  endif

  call codex#AppendText("## User\n" . a:text . "\n\n## Codex")

  call s:HTTP.request_async({
        \ "url": s:ENDPOINT_URL,
        \ "method": "POST",
        \ "headers": s:HEADERS,
        \ "data": json_encode(payload),
        \ "exit_cb": "codex#ExitCb"
        \})
endfunction

function! codex#RequestFromBuffer() abort
  " 入力専用バッファの内容を結合して送信
  let name = s:REQUEST_BUFFER_NAME
  let buf  = bufnr(name)
  if buf == -1
    call codex#OpenRequestBuffer()
    let buf = bufnr(name)
  endif

  if !bufloaded(buf)
    call bufload(buf)
  endif

  let lines = getbufline(buf, 1, '$')
  if len(lines) == 1 && lines[0] ==# ''
    echo '[codex] Request buffer is empty'
    return
  endif

  let text = join(lines, "\n")
  call codex#Request(text)

  " 入力専用バッファの内容をクリア
  call deletebufline(buf, 1, '$')
endfunction

function! codex#ResetContext() abort
  let s:prev_response_id = ''
endfunction

" レスポンスJSONからアシスタントのテキストを安全に取り出す
function! s:ExtractText(body_json) abort
  " 0) 便利プロパティ（あれば最優先）
  if has_key(a:body_json, 'output_text')
        \ && type(a:body_json.output_text) == v:t_string
        \ && !empty(a:body_json.output_text)
    return a:body_json.output_text
  endif

  " 1) output を走査して、assistant の message に含まれる text を集める
  if has_key(a:body_json, 'output') && type(a:body_json.output) == v:t_list
    let acc = []
    for item in a:body_json.output
      " web_search_call などの中間ステップは無視
      if get(item, 'type', '') ==# 'message'
            \ && get(item, 'role', '') ==# 'assistant'
            \ && has_key(item, 'content') && type(item.content) == v:t_list
        for c in item.content
          if has_key(c, 'text') && type(c.text) == v:t_string
            call add(acc, c.text)
          endif
        endfor
      endif
    endfor
    if !empty(acc)
      return join(acc, "\n")
    endif
  endif

  " 2) フォールバック：何も拾えなければ空文字
  return ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
