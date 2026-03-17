void
shift(unsigned int *tag, int i)
{
	if (i > 0)
		*tag = ((*tag << i) | (*tag >> (LENGTH(tags) - i)));
	else
		*tag = (*tag >> (-i) | *tag << (LENGTH(tags) + i));
}

void
shiftview(const Arg *arg)
{
	Arg shifted = { .ui = selmon->tagset[selmon->seltags] };
	shift(&shifted.ui, arg->i);
	view(&shifted);
}

void
shifttag(const Arg *arg)
{
	Arg shifted = { .ui = selmon->tagset[selmon->seltags] };
	if (!selmon->clients)
		return;
	shift(&shifted.ui, arg->i);
	tag(&shifted);
}
