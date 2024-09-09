#include "ruby/ruby.h"
#include "hashids.h"

void wrapped_hashids_free(void* data)
{
    hashids_free(data);
}

size_t wrapped_hashids_size(const void* data)
{
    return sizeof(hashids_t);
}

static const rb_data_type_t wrapped_hashids_type = {
    .wrap_struct_name = "hashids_t",
    .function = {
        .dmark = NULL,
        .dfree = wrapped_hashids_free,
        .dsize = wrapped_hashids_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

VALUE hashids_alloc(VALUE self)
{
    hashids_t *data = hashids_init("salt!");
    return TypedData_Wrap_Struct(self, &wrapped_hashids_type, data);
}

//VALUE rb_hashids_m_initialize(VALUE self, VALUE val)
//{
//    return self;
//}


static VALUE rb_hash_id_c_encode(VALUE self, VALUE ids) {
    Check_Type(ids, T_ARRAY);

    long length = RARRAY_LEN(ids);

    unsigned long long* inputs = ALLOC_N(unsigned long long, length);

    for (long i = 0; i < length; i++) {
        VALUE rb_element = rb_ary_entry(ids, i);
        Check_Type(rb_element, T_FIXNUM);
        inputs[i] = NUM2ULL(rb_element);
    }

    hashids_t* hashids;

    TypedData_Get_Struct(self, hashids_t, &wrapped_hashids_type, hashids);

    size_t bytes_encoded;

    size_t bytes_needed;
    bytes_needed = hashids_estimate_encoded_size(hashids, sizeof(&inputs) / sizeof(unsigned long long), &inputs);
    char *hash = ALLOC_N(char, bytes_needed);

    // unsigned long long numbers[] = {1ull, 2ull, 3ull, 4ull, 5ull};

//    printf("length: %ld\n", length);
//    printf("inputs[0]: %llu\n", inputs[0]);
//    printf("inputs[1]: %llu\n", inputs[1]);
//    printf("inputs[2]: %llu\n", inputs[2]);
//    printf("inputs[3]: %llu\n", inputs[3]);
//    printf("inputs[4]: %llu\n", inputs[4]);
//
//    printf("hashids: %p\n", hashids);
//    printf("hashids->alphabet: %s\n", hashids->alphabet);
//    printf("hashids->salt: %s\n", hashids->salt);
//    printf("hashids->min_hash_length: %lu\n", hashids->min_hash_length);
//    printf("numbers: %p\n", numbers);
//    printf("numbers[0]: %llu\n", numbers[0]);
//    printf("numbers[1]: %llu\n", numbers[1]);
//    printf("numbers[2]: %llu\n", numbers[2]);
//    printf("numbers[3]: %llu\n", numbers[3]);
//    printf("numbers[4]: %llu\n", numbers[4]);
//
//    printf("sizeof(*inputs) / sizeof(unsigned long long): %lu\n", sizeof(*inputs) / sizeof(unsigned long long));
//    printf("sizeof(numbers) / sizeof(unsigned long long): %lu\n", sizeof(numbers) / sizeof(unsigned long long));
    // bytes_encoded = hashids_encode(hashids, hash, sizeof(numbers) / sizeof(unsigned long long), numbers);
    bytes_encoded = hashids_encode(hashids, hash, length, inputs);

    ruby_xfree(inputs);
    VALUE return_value = rb_str_new2(hash);
    ruby_xfree(hash);
    return return_value;
}

static VALUE rb_hash_id_c_decode(VALUE self, VALUE str) {
    Check_Type(str, T_STRING);

    hashids_t* hashids;

    TypedData_Get_Struct(self, hashids_t, &wrapped_hashids_type, hashids);

    size_t numbers_count = hashids_numbers_count(hashids, RSTRING_PTR(str));

    unsigned long long* numbers = ALLOC_N(unsigned long long, numbers_count);

    hashids_decode(hashids, RSTRING_PTR(str), numbers, numbers_count);

    VALUE rb_numbers = rb_ary_new_capa(numbers_count);

    for (size_t i = 0; i < numbers_count; i++) {
        rb_ary_push(rb_numbers, ULL2NUM(numbers[i]));
    }

    ruby_xfree(numbers);
    return rb_numbers;
}

void Init_extension(void) {
    VALUE EncodedId = rb_define_module("EncodedId");
    VALUE HashIdC = rb_define_class_under(EncodedId, "HashIdC", rb_cObject);

    rb_define_alloc_func(HashIdC, hashids_alloc);
//    rb_define_method(HashIdC, "initialize", rb_hashids_m_initialize, 1);

    rb_define_method(HashIdC, "encode", rb_hash_id_c_encode, 1);
    rb_define_method(HashIdC, "decode", rb_hash_id_c_decode, 1);
}
