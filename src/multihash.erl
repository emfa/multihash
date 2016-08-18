-module(multihash).

-export([hash/2]).
-export([hash/3]).
-export([decode/1]).

hash(HashFunAtom, Binary) ->
    hash(HashFunAtom, undefined, Binary).

hash(HashFunAtom, Size0, Binary) ->
    {HashFunAtom, HashFunCode, HashFun} = hash_fun_info(HashFunAtom),
    {Digest, Size} = case HashFun(Binary) of
                         <<PartDigest:Size0/binary, _/binary>> ->
                             {PartDigest, Size0};
                         FullDigest ->
                             {FullDigest, byte_size(FullDigest)}
                     end,
    <<(encode_uvarint(HashFunCode))/binary,
      (encode_uvarint(Size))/binary,
      Digest/binary>>.

decode(Binary) ->
    {HashFunCode, Rest0} = decode_uvarint(Binary),
    HashFun = hash_fun_code_to_atom(HashFunCode),
    {DigestSize, Rest1} = decode_uvarint(Rest0),
    <<Digest:DigestSize/binary, Rest2/binary>> = Rest1,
    {HashFun, Digest, Rest2}.

hash_fun_info('sha1') ->
    {'sha1', 16#11, fun (Binary) -> crypto:hash(sha, Binary) end};
hash_fun_info('sha2-256') ->
    {'sha2-256', 16#12, fun (Binary) -> crypto:hash(sha256, Binary) end};
hash_fun_info('sha2-512') ->
    {'sha2-512', 16#13, fun (Binary) -> crypto:hash(sha512, Binary) end};
hash_fun_info('sha3-512') ->
    {'sha3-512', 16#14, undefined};
hash_fun_info('sha3-384') ->
    {'sha3-384', 16#15, undefined};
hash_fun_info('sha3-256') ->
    {'sha3-256', 16#16, undefined};
hash_fun_info('sha3-224') ->
    {'sha3-224', 16#17, undefined};
hash_fun_info('shake-128') ->
    {'shake-128', 16#18, undefined};
hash_fun_info('shake-256') ->
    {'shake-256', 16#19, undefined};
hash_fun_info('blake2b') ->
    {'blake2b', 16#40, undefined};
hash_fun_info('blake2s') ->
    {'blake2s', 16#41, undefined}.

hash_fun_code_to_atom(16#11) -> 'sha1';
hash_fun_code_to_atom(16#12) -> 'sha2-256';
hash_fun_code_to_atom(16#13) -> 'sha2-512';
hash_fun_code_to_atom(16#14) -> 'sha3-512';
hash_fun_code_to_atom(16#15) -> 'sha3-384';
hash_fun_code_to_atom(16#16) -> 'sha3-256';
hash_fun_code_to_atom(16#17) -> 'sha3-224';
hash_fun_code_to_atom(16#18) -> 'shake-128';
hash_fun_code_to_atom(16#19) -> 'shake-256';
hash_fun_code_to_atom(16#40) -> 'blake2b';
hash_fun_code_to_atom(16#41) -> 'blake2s'.

encode_uvarint(Int) when Int >= 0, Int < 128 ->
    <<Int>>.

decode_uvarint(<<Int, Rest/binary>>) when Int >= 0, Int < 128 ->
    {Int, Rest}.
