////
//// Gleam code from json schema content generator.
////

import gleam/dict
import gleam/list

import gbr/json/schema/ast
import gbr/json/schema/domain as castor
import gbr/json/schema/lift
import gbr/json/schema/types
import gbr/shared/lookup as l

pub fn generate(schemas) {
  let #(internal, named) =
    list.map_fold(schemas |> dict.to_list, [], fn(acc, entry) {
      let #(name, schema) = entry
      let #(top, _nullable, acc) = lift.do_lift(castor.Inline(schema), acc)
      #(acc, #(name, top))
    })
  let named =
    list.append(
      named,
      internal
        |> list.unique
        |> list.reverse
        |> list.map(fn(entry) {
          let #(hash, fields) = entry
          #(lift.content_id_to_fn_prefix(hash), lift.Compound(fields))
        }),
    )

  l.fold(named, #([], [], []), fn(acc, entry) {
    let #(name, top) = entry
    let #(custom_types, type_aliases, fns) = acc
    use enc_fn <- l.then(types.to_encode_fn(#(name, top)))
    use dec_fn <- l.then(types.to_decode_fn(#(name, top)))
    let fns = list.append(fns, [enc_fn, dec_fn])
    let name = ast.name_for_gleam_type(name)
    use #(custom_types, type_aliases) <- l.then(case top {
      lift.Named(name) -> {
        use type_ <- l.then(types.to_type(lift.Named(name)))
        l.Done(#(custom_types, [types.alias(name, type_), ..type_aliases]))
      }
      lift.Primitive(primitive) -> {
        use type_ <- l.then(types.to_type(lift.Primitive(primitive)))
        l.Done(#(custom_types, [types.alias(name, type_), ..type_aliases]))
      }
      lift.Array(items) -> {
        use type_ <- l.then(types.to_type(lift.Array(items)))
        l.Done(#(custom_types, [types.alias(name, type_), ..type_aliases]))
      }
      lift.Tuple(items) -> {
        use type_ <- l.then(types.to_type(lift.Tuple(items)))
        l.Done(#(custom_types, [types.alias(name, type_), ..type_aliases]))
      }
      lift.Compound(lift.Fields(properties, additional, required)) -> {
        use type_ <- l.then(types.custom_type(
          name,
          properties,
          additional,
          required,
        ))
        l.Done(#([type_, ..custom_types], type_aliases))
      }
      lift.Dictionary(values) -> {
        use type_ <- l.then(types.to_type(lift.Dictionary(values)))
        l.Done(#(custom_types, [types.alias(name, type_), ..type_aliases]))
      }
      lift.Unsupported -> {
        use type_ <- l.then(types.to_type(lift.Unsupported))
        l.Done(#(custom_types, [types.alias(name, type_), ..type_aliases]))
      }
    })
    l.Done(#(custom_types, type_aliases, fns))
  })
}
