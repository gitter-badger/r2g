
const args = process.argv.slice(2);
console.log(args.length);
console.log(args);

console.log('my args:',process.env.my_args);

exports.foo = 'bar';

setTimeout(function () {
  console.log(require(__filename).foo);
},100);
